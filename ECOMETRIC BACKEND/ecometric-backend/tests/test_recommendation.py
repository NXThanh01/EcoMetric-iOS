import unittest

from pydantic import ValidationError

from fastapi import HTTPException

from main import EnergyInput, recommend


class RecommendationTests(unittest.TestCase):
    def make_input(self, **overrides):
        values = {
            "facility_name": "Xưởng 1",
            "problem_type": "lighting_high_consumption",
            "lamp_quantity": 100,
            "current_power_w": 40,
            "proposed_power_w": 18,
            "hours_per_day": 16,
            "days_per_month": 30,
            "electricity_price_vnd_per_kwh": 2367,
            "investment_vnd": 15_000_000,
        }
        values.update(overrides)
        return EnergyInput(**values)

    def test_led_recommendation_calculation(self):
        result = recommend(self.make_input())

        self.assertEqual(result.energy_saving_kwh_month, 1056.0)
        self.assertEqual(result.cost_saving_vnd_month, 2_499_552.0)
        self.assertEqual(result.cost_saving_vnd_year, 29_994_624.0)
        self.assertEqual(result.payback_months, 6.0)
        self.assertIsNone(result.co2_reduction)
        self.assertFalse(result.emission_factor_verified)

    def test_rejects_negative_quantity(self):
        with self.assertRaises(ValidationError):
            self.make_input(lamp_quantity=-1)

    def test_rejects_proposed_power_above_current_power(self):
        with self.assertRaises(HTTPException) as context:
            recommend(
                self.make_input(
                    current_power_w=18,
                    proposed_power_w=40,
                )
            )

        self.assertEqual(context.exception.status_code, 422)


if __name__ == "__main__":
    unittest.main()
