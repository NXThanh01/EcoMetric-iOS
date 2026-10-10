import unittest
from datetime import datetime, timedelta

from pydantic import ValidationError

from schemas import EnergyTimeSeriesInput, EnergyTimeSeriesPoint
from services.time_series_service import analyze_time_series


class TimeSeriesAnalysisTests(unittest.TestCase):
    def make_points(
        self,
        consumption_values,
        production_values=None,
    ):
        start = datetime(2026, 9, 1)
        points = []
        for index, consumption in enumerate(consumption_values):
            production = (
                production_values[index]
                if production_values is not None
                else None
            )
            points.append(
                EnergyTimeSeriesPoint(
                    timestamp=start + timedelta(days=index),
                    consumption_kwh=consumption,
                    production_units=production,
                )
            )
        return points

    def test_detects_high_consumption_anomaly(self):
        data = EnergyTimeSeriesInput(
            facility_name="Xưởng 1",
            points=self.make_points([100, 101, 99, 100, 102, 98, 160]),
        )

        result = analyze_time_series(data)

        self.assertEqual(result.engine_version, "1.2.0")
        self.assertEqual(len(result.anomalies), 1)
        self.assertEqual(result.anomalies[0].actual_kwh, 160)
        self.assertEqual(result.anomalies[0].expected_kwh, 100)
        self.assertEqual(result.anomalies[0].excess_kwh, 60)
        self.assertEqual(
            result.opportunities[0].problem_type,
            "abnormal_energy_consumption",
        )
        self.assertEqual(result.summary.status, "attention")
        self.assertEqual(result.summary.total_excess_kwh, 60)
        self.assertEqual(result.summary.anomaly_rate_percent, 14.3)
        self.assertEqual(
            result.diagnoses[0].code,
            "unexplained_load_increase",
        )
        self.assertEqual(result.recommended_actions[0].priority, 1)

    def test_normalizes_consumption_by_production(self):
        production = [100, 110, 120, 130, 140, 150, 160]
        consumption = [value * 10 for value in production]
        data = EnergyTimeSeriesInput(
            facility_name="Xưởng 1",
            points=self.make_points(consumption, production),
        )

        result = analyze_time_series(data)

        self.assertEqual(
            result.baseline.normalized_by,
            "production_units",
        )
        self.assertEqual(result.baseline.median, 10)
        self.assertFalse(result.anomalies)
        self.assertEqual(result.summary.status, "normal")
        self.assertFalse(result.next_questions)

    def test_explains_anomaly_after_normalizing_by_production(self):
        production = [10] * 7
        data = EnergyTimeSeriesInput(
            facility_name="Xưởng 1",
            points=self.make_points(
                [100, 101, 99, 100, 102, 98, 160],
                production,
            ),
        )

        result = analyze_time_series(data)

        self.assertEqual(
            result.diagnoses[0].code,
            "process_efficiency_drop",
        )
        self.assertTrue(
            any(
                "chạy không tải" in action.title.lower()
                for action in result.recommended_actions
            )
        )

    def test_detects_rising_normalized_baseline(self):
        values = [100] * 7 + [120] * 7
        data = EnergyTimeSeriesInput(
            facility_name="Xưởng 1",
            points=self.make_points(values),
        )

        result = analyze_time_series(data)

        self.assertEqual(result.baseline.trend_percent, 20)
        self.assertTrue(
            any(
                item.problem_type == "rising_energy_baseline"
                for item in result.opportunities
            )
        )

    def test_requires_at_least_seven_points(self):
        with self.assertRaises(ValidationError):
            EnergyTimeSeriesInput(
                facility_name="Xưởng 1",
                points=self.make_points([100] * 6),
            )


if __name__ == "__main__":
    unittest.main()
