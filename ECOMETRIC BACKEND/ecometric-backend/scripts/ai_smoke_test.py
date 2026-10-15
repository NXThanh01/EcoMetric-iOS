"""Thử AI thật với số liệu tổng hợp, không ghi DB hoặc gửi email."""
import argparse
import sys
import time
import uuid
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from schemas import EnergyTimeSeriesInput, EnergyTimeSeriesPoint
from services.time_series_service import analyze_time_series
from services.gemini_insight_service import GeminiInsightService, GeminiGenerationError, GeminiNotConfiguredError


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--advisor", action="store_true", help="Gọi thêm chatbot; có sử dụng quota AI.")
    args = parser.parse_args()
    data = EnergyTimeSeriesInput(facility_name="Cơ sở kiểm thử tổng hợp", interval="daily",
        points=[EnergyTimeSeriesPoint(timestamp=datetime(2026, 10, 1) + timedelta(days=index),
            consumption_kwh=value, production_units=10, operating_hours=8)
            for index, value in enumerate([100, 101, 99, 100, 102, 98, 160])])
    analysis = analyze_time_series(data)
    dataset_id = uuid.uuid4()
    service = GeminiInsightService()
    started = time.monotonic()
    try:
        result = service.generate_dataset_insight(dataset_id, data, analysis,
            operational_context="Máy nén khí chạy ngoài giờ ở kỳ cuối.",
            desired_outcome="Giảm điện và giữ nguyên sản lượng.")
        assert result.insight.recommendations, "AI chưa trả về giải pháp"
        assert result.quantitative_analysis.summary.total_excess_kwh == 60, "Số liệu Engine đã thay đổi"
        print(f"✓ AI thực: {len(result.insight.recommendations)} giải pháp, model {result.model}, {time.monotonic() - started:.1f}s")
        if args.advisor:
            answer = service.answer_dataset_question(dataset_id, data, analysis,
                question="Nên kiểm tra nguyên nhân nào trước và dùng chỉ số nào để đo lại?", history=[])
            assert answer.answer.answer, "Chatbot chưa có câu trả lời"
            print(f"✓ Chatbot thực: có câu trả lời, {len(answer.answer.evidence)} bằng chứng")
    except (GeminiGenerationError, GeminiNotConfiguredError, AssertionError) as error:
        print(f"✗ {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
