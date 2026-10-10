import unittest

from fastapi import HTTPException

from schemas import EnergyInput
from services.opportunity_service import analyze_energy_input
from services.recommendation_service import build_recommendations
from services.scoring_service import score_recommendation


class RecommendationEngineTests(unittest.TestCase):
    def setUp(self):
        self.input = EnergyInput(
            facility_name="Xưởng 1",
            problem_type="lighting_high_consumption",
            lamp_quantity=100,
            current_power_w=40,
            proposed_power_w=18,
            hours_per_day=16,
            days_per_month=30,
            electricity_price_vnd_per_kwh=2367,
            investment_vnd=15_000_000,
        )

    def test_detects_lighting_opportunity(self):
        opportunity = analyze_energy_input(self.input)

        self.assertEqual(
            opportunity.problem_type,
            "lighting_high_consumption",
        )
        self.assertEqual(
            opportunity.evidence["current_energy_kwh_month"],
            1920.0,
        )
        self.assertEqual(opportunity.severity, 0.96)
        self.assertEqual(opportunity.confidence, 0.95)

    def test_builds_and_ranks_multiple_recommendations(self):
        result = build_recommendations(self.input)

        self.assertEqual(len(result.recommendations), 2)
        self.assertEqual(
            result.recommendations[0].knowledge_id,
            "energy_led_001",
        )
        self.assertEqual(
            result.recommendations[0].ranking.priority,
            "high",
        )
        self.assertGreater(
            result.recommendations[0].ranking.score,
            result.recommendations[1].ranking.score,
        )

    def test_assumption_reduces_data_confidence(self):
        result = build_recommendations(self.input)
        schedule = next(
            item
            for item in result.recommendations
            if item.knowledge_id == "energy_lighting_schedule_001"
        )

        self.assertEqual(schedule.data_quality.score, 0.75)
        self.assertTrue(schedule.data_quality.assumptions)
        self.assertFalse(schedule.source.verified)

    def test_unverified_source_lowers_score(self):
        result = build_recommendations(self.input)
        led, schedule = result.recommendations

        self.assertEqual(
            led.ranking.components["source_quality"],
            100,
        )
        self.assertEqual(
            schedule.ranking.components["source_quality"],
            30,
        )

    def test_returns_explainable_savings_scenarios(self):
        result = build_recommendations(self.input)
        led = result.recommendations[0]

        self.assertEqual(result.engine_version, "1.0.0")
        self.assertLess(
            led.scenarios.conservative.cost_saving_vnd_year,
            led.scenarios.expected.cost_saving_vnd_year,
        )
        self.assertGreater(
            led.scenarios.optimistic.cost_saving_vnd_year,
            led.scenarios.expected.cost_saving_vnd_year,
        )
        self.assertTrue(led.rationale)
        self.assertTrue(led.verification_plan)

    def test_filters_solution_when_applicability_rule_fails(self):
        short_shift = self.input.model_copy(
            update={"hours_per_day": 6},
        )
        result = build_recommendations(short_shift)

        self.assertEqual(len(result.recommendations), 1)
        self.assertEqual(
            result.recommendations[0].knowledge_id,
            "energy_led_001",
        )

    def test_rejects_when_no_solution_is_applicable(self):
        unsuitable = self.input.model_copy(
            update={"hours_per_day": 3},
        )

        with self.assertRaises(HTTPException) as context:
            build_recommendations(unsuitable)

        self.assertEqual(context.exception.status_code, 422)

    def test_measured_data_without_duration_lowers_confidence(self):
        measured = self.input.model_copy(
            update={
                "data_source": "measured",
                "measurement_days": None,
            },
        )
        result = build_recommendations(measured)
        led = result.recommendations[0]

        self.assertEqual(led.data_quality.score, 0.85)
        self.assertIn(
            "measurement_days",
            led.data_quality.missing_fields,
        )


if __name__ == "__main__":
    unittest.main()
