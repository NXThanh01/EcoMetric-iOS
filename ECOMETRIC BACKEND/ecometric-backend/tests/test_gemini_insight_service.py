import unittest
import uuid
from datetime import datetime, timedelta

from gemini_schemas import GeminiNarrative
from schemas import EnergyTimeSeriesInput, EnergyTimeSeriesPoint
from services.gemini_insight_service import (
    GeminiInsightService,
    GeminiNotConfiguredError,
)
from services.time_series_service import analyze_time_series


class FakeGeminiResponse:
    def __init__(self, text=None, parsed=None):
        self.text = text
        self.parsed = parsed


class FakeGeminiModels:
    def __init__(self, narrative):
        self.narrative = narrative
        self.last_request = None

    def generate_content(self, **kwargs):
        self.last_request = kwargs
        return FakeGeminiResponse(self.narrative.model_dump_json())


class FakeGeminiClient:
    def __init__(self, narrative):
        self.models = FakeGeminiModels(narrative)


class FlakyGeminiModels:
    def __init__(self, narrative):
        self.narrative = narrative
        self.call_count = 0

    def generate_content(self, **kwargs):
        self.call_count += 1
        if self.call_count == 1:
            return FakeGeminiResponse(text="không phải JSON")
        return FakeGeminiResponse(parsed=self.narrative)


class FlakyGeminiClient:
    def __init__(self, narrative):
        self.models = FlakyGeminiModels(narrative)


class GeminiInsightServiceTests(unittest.TestCase):
    def make_input(self):
        start = datetime(2026, 10, 1)
        values = [100, 101, 99, 100, 102, 98, 160]
        return EnergyTimeSeriesInput(
            facility_name="Xưởng 1",
            interval="daily",
            points=[
                EnergyTimeSeriesPoint(
                    timestamp=start + timedelta(days=index),
                    consumption_kwh=value,
                    production_units=10,
                    operating_hours=8,
                )
                for index, value in enumerate(values)
            ],
        )

    def make_narrative(self):
        return GeminiNarrative(
            headline="Một kỳ tiêu thụ điện cần được kiểm tra",
            executive_summary=(
                "Dữ liệu cho thấy một kỳ cao hơn đường cơ sở sau khi chuẩn hóa."
            ),
            root_causes=[
                {
                    "title": "Có thể có thiết bị chạy không tải",
                    "explanation": "Đây là giả thuyết cần đối chiếu nhật ký.",
                    "evidence": ["Điện năng trên sản lượng tăng tại một kỳ."],
                    "confidence_reason": "Có sản lượng tương ứng nhưng chỉ có 7 kỳ.",
                }
            ],
            recommendations=[
                {
                    "priority": 1,
                    "title": "Kiểm tra nhật ký vận hành",
                    "steps": ["Đối chiếu ca sản xuất", "Kiểm tra tải không cần thiết"],
                    "expected_outcome": "Xác định được phụ tải gây tăng điện.",
                    "verification_metric": "kWh/đơn vị trở về gần đường cơ sở",
                }
            ],
            caveats=["Chỉ có 7 kỳ dữ liệu."],
            follow_up_questions=["Thiết bị nào chạy tại kỳ bất thường?"],
        )

    def test_generates_structured_vietnamese_insight(self):
        data = self.make_input()
        analysis = analyze_time_series(data)
        fake_client = FakeGeminiClient(self.make_narrative())
        service = GeminiInsightService(
            model="gemini-test",
            fallback_model=None,
            client=fake_client,
        )

        result = service.generate_dataset_insight(
            dataset_id=uuid.uuid4(),
            data=data,
            analysis=analysis,
        )

        self.assertEqual(result.provider, "gemini")
        self.assertEqual(result.model, "gemini-test")
        self.assertEqual(result.quantitative_analysis.summary.total_excess_kwh, 60)
        self.assertEqual(result.insight.recommendations[0].priority, 1)
        self.assertIn(
            "Không tự tạo số liệu",
            fake_client.models.last_request["contents"],
        )
        self.assertEqual(
            fake_client.models.last_request["model"],
            "gemini-test",
        )

    def test_requires_api_key_when_no_client_is_injected(self):
        data = self.make_input()
        analysis = analyze_time_series(data)
        service = GeminiInsightService(api_key="", model="gemini-test")
        service.api_key = None

        with self.assertRaises(GeminiNotConfiguredError):
            service.generate_dataset_insight(
                dataset_id=uuid.uuid4(),
                data=data,
                analysis=analysis,
            )

    def test_retries_and_uses_sdk_parsed_response(self):
        data = self.make_input()
        analysis = analyze_time_series(data)
        fake_client = FlakyGeminiClient(self.make_narrative())
        service = GeminiInsightService(
            model="gemini-test",
            fallback_model=None,
            client=fake_client,
        )

        result = service.generate_dataset_insight(
            dataset_id=uuid.uuid4(),
            data=data,
            analysis=analysis,
        )

        self.assertEqual(fake_client.models.call_count, 2)
        self.assertEqual(result.insight.headline, self.make_narrative().headline)


if __name__ == "__main__":
    unittest.main()
