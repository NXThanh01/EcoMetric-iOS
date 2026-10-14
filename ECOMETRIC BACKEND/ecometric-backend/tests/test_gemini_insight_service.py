import unittest
import uuid
from datetime import datetime, timedelta

from gemini_schemas import AdvisorHistoryMessage, DatasetAdvisorAnswer, GeminiNarrative
from schemas import EnergyTimeSeriesInput, EnergyTimeSeriesPoint
from services.gemini_insight_service import (
    GeminiInsightService,
    GeminiNotConfiguredError,
    GeminiGenerationError,
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
    def test_overload_switches_model_without_repeating_failed_model(self):
        from types import SimpleNamespace
        calls = []
        narrative = self.make_narrative()
        def generate(**kwargs):
            calls.append(kwargs["model"])
            if kwargs["model"] == "primary":
                error = RuntimeError("quá tải")
                error.code = 503
                raise error
            return FakeGeminiResponse(parsed=narrative)
        service = GeminiInsightService(model="primary", fallback_model="fallback",
            client=SimpleNamespace(models=SimpleNamespace(generate_content=generate)))
        data = self.make_input()
        result = service.generate_dataset_insight(uuid.uuid4(), data, analyze_time_series(data))
        self.assertEqual(calls, ["primary", "fallback"])
        self.assertEqual(result.model, "fallback")

    def test_invalid_key_fails_fast_with_safe_message(self):
        from types import SimpleNamespace
        calls = []
        def generate(**kwargs):
            calls.append(kwargs["model"])
            error = RuntimeError("khóa bí mật không được ghi ra")
            error.code = 403
            raise error
        service = GeminiInsightService(model="primary", fallback_model="fallback",
            client=SimpleNamespace(models=SimpleNamespace(generate_content=generate)))
        data = self.make_input()
        with self.assertRaises(GeminiGenerationError) as caught:
            service.generate_dataset_insight(uuid.uuid4(), data, analyze_time_series(data))
        self.assertEqual(calls, ["primary"])
        self.assertEqual(caught.exception.status_code, 503)
        self.assertNotIn("bí mật", str(caught.exception))

    def test_quota_is_not_retried_repeatedly(self):
        from types import SimpleNamespace
        calls = []
        def generate(**kwargs):
            calls.append(kwargs["model"])
            error = RuntimeError("quota")
            error.code = 429
            raise error
        service = GeminiInsightService(model="primary", fallback_model="fallback",
            client=SimpleNamespace(models=SimpleNamespace(generate_content=generate)))
        data = self.make_input()
        with self.assertRaises(GeminiGenerationError) as caught:
            service.generate_dataset_insight(uuid.uuid4(), data, analyze_time_series(data))
        self.assertEqual(calls, ["primary", "fallback"])
        self.assertIn("quota", str(caught.exception))
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

    def test_advisor_is_grounded_in_engine_and_user_context(self):
        data = self.make_input()
        analysis = analyze_time_series(data)
        answer = DatasetAdvisorAnswer(
            answer="Kỳ cuối cần được đối chiếu nhật ký vận hành.",
            evidence=["Engine phát hiện một kỳ vượt đường cơ sở."],
            suggested_actions=["Kiểm tra tải chạy ngoài ca."],
            verification_metric="kWh/đơn vị sau điều chỉnh",
            follow_up_questions=["Thiết bị nào hoạt động ngoài ca?"],
        )
        fake_client = FakeGeminiClient(answer)
        service = GeminiInsightService(
            model="gemini-test",
            fallback_model=None,
            client=fake_client,
        )

        result = service.answer_dataset_question(
            dataset_id=uuid.uuid4(),
            data=data,
            analysis=analysis,
            question="Tôi nên xử lý gì trước?",
            history=[AdvisorHistoryMessage(role="user", content="Xưởng chạy hai ca")],
            operational_context="Máy nén khí chạy trong giờ nghỉ",
            desired_outcome="Giảm điện mà không giảm sản lượng",
        )

        prompt = fake_client.models.last_request["contents"]
        self.assertEqual(result.answer.verification_metric, "kWh/đơn vị sau điều chỉnh")
        self.assertIn("Máy nén khí chạy trong giờ nghỉ", prompt)
        self.assertIn("không phải chatbot kiến thức chung", prompt)


if __name__ == "__main__":
    unittest.main()
