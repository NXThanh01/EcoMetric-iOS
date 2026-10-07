import unittest

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


if __name__ == "__main__":
    unittest.main()
