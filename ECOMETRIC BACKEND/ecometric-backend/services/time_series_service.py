from statistics import mean, median
from typing import List, Optional, Tuple

from schemas import (
    EnergyAnomaly,
    EnergyBaseline,
    EnergyInsightSummary,
    EnergyTimeSeriesInput,
    EnergyTimeSeriesPoint,
    Opportunity,
    RecommendedAction,
    RootCauseHypothesis,
    TimeSeriesAnalysisResponse,
)


ENGINE_VERSION = "1.2.0"
MINIMUM_DEVIATION_PERCENT = 20
ROBUST_Z_THRESHOLD = 3


def _select_metric(
    points: List[EnergyTimeSeriesPoint],
) -> Tuple[str, str, List[float]]:
    if all(point.production_units is not None for point in points):
        return (
            "production_units",
            "kWh/đơn vị sản phẩm",
            [
                point.consumption_kwh / point.production_units
                for point in points
                if point.production_units is not None
            ],
        )

    if all(point.operating_hours is not None for point in points):
        return (
            "operating_hours",
            "kWh/giờ vận hành",
            [
                point.consumption_kwh / point.operating_hours
                for point in points
                if point.operating_hours is not None
            ],
        )

    return (
        "consumption",
        "kWh",
        [point.consumption_kwh for point in points],
    )


def _expected_consumption(
    point: EnergyTimeSeriesPoint,
    baseline_metric: float,
    normalized_by: str,
) -> float:
    if normalized_by == "production_units":
        return baseline_metric * (point.production_units or 0)
    if normalized_by == "operating_hours":
        return baseline_metric * (point.operating_hours or 0)
    return baseline_metric


def _trend_percent(values: List[float]) -> Optional[float]:
    if len(values) < 14:
        return None

    recent = mean(values[-7:])
    previous = mean(values[-14:-7])
    if previous == 0:
        return None
    return round((recent - previous) / previous * 100, 1)


def _confidence(
    point_count: int,
    normalized_by: str,
) -> float:
    coverage_score = min(point_count / 30, 1) * 0.25
    normalization_bonus = 0.10 if normalized_by != "consumption" else 0
    return round(min(0.60 + coverage_score + normalization_bonus, 0.95), 2)


def _build_summary(
    anomalies: List[EnergyAnomaly],
    point_count: int,
) -> EnergyInsightSummary:
    total_excess_kwh = round(
        sum(anomaly.excess_kwh for anomaly in anomalies),
        2,
    )
    anomaly_rate = round(len(anomalies) / point_count * 100, 1)
    maximum_severity = max(
        (anomaly.severity for anomaly in anomalies),
        default=0,
    )

    if maximum_severity >= 0.7 or anomaly_rate >= 25:
        status = "critical"
        message = (
            "Mức tiêu thụ bất thường cần được kiểm tra sớm để hạn chế "
            "điện năng lãng phí."
        )
    elif anomalies:
        status = "attention"
        message = (
            "Đã phát hiện điểm tiêu thụ cao hơn đường cơ sở và cần đối chiếu "
            "với lịch vận hành."
        )
    else:
        status = "normal"
        message = "Chưa phát hiện mức tiêu thụ cao bất thường trong kỳ dữ liệu."

    return EnergyInsightSummary(
        status=status,
        total_excess_kwh=total_excess_kwh,
        anomaly_rate_percent=anomaly_rate,
        message=message,
    )


def _build_diagnoses(
    normalized_by: str,
    anomalies: List[EnergyAnomaly],
    trend: Optional[float],
    confidence: float,
) -> List[RootCauseHypothesis]:
    diagnoses = []
    if anomalies and normalized_by == "production_units":
        diagnoses.append(
            RootCauseHypothesis(
                code="process_efficiency_drop",
                title="Hiệu suất năng lượng theo sản lượng suy giảm",
                description=(
                    "Điện năng tăng sau khi đã loại trừ ảnh hưởng của sản lượng. "
                    "Cần kiểm tra thiết bị, chế độ chạy không tải hoặc thay đổi quy trình."
                ),
                confidence=round(confidence * 0.9, 2),
                evidence=[
                    "Đường cơ sở được chuẩn hóa theo sản lượng.",
                    f"Có {len(anomalies)} kỳ vượt ngưỡng bất thường.",
                ],
            )
        )
    elif anomalies and normalized_by == "operating_hours":
        diagnoses.append(
            RootCauseHypothesis(
                code="load_efficiency_drop",
                title="Phụ tải theo giờ vận hành tăng",
                description=(
                    "Mức điện trên mỗi giờ hoạt động cao hơn bình thường. "
                    "Có thể tồn tại thiết bị chạy quá tải hoặc phụ tải phụ không cần thiết."
                ),
                confidence=round(confidence * 0.85, 2),
                evidence=[
                    "Đường cơ sở được chuẩn hóa theo giờ vận hành.",
                    f"Có {len(anomalies)} kỳ vượt ngưỡng bất thường.",
                ],
            )
        )
    elif anomalies:
        diagnoses.append(
            RootCauseHypothesis(
                code="unexplained_load_increase",
                title="Phụ tải tổng tăng chưa xác định nguyên nhân",
                description=(
                    "Dữ liệu hiện tại cho thấy điện năng tăng nhưng chưa đủ sản lượng "
                    "hoặc giờ vận hành để tách ảnh hưởng hoạt động."
                ),
                confidence=round(confidence * 0.7, 2),
                evidence=[
                    "Phân tích đang dùng điện năng tuyệt đối.",
                    f"Có {len(anomalies)} kỳ vượt ngưỡng bất thường.",
                ],
            )
        )

    if trend is not None and trend >= 10:
        diagnoses.append(
            RootCauseHypothesis(
                code="baseline_drift",
                title="Đường cơ sở tiêu thụ đang tăng",
                description=(
                    "Bảy kỳ gần nhất có mức tiêu thụ chuẩn hóa cao hơn bảy kỳ trước. "
                    "Đây có thể là dấu hiệu suy giảm hiệu suất dần theo thời gian."
                ),
                confidence=round(confidence * 0.8, 2),
                evidence=[f"Xu hướng 7 kỳ gần nhất tăng {trend:.1f}%."],
            )
        )

    return diagnoses


def _build_actions(
    normalized_by: str,
    anomalies: List[EnergyAnomaly],
    trend: Optional[float],
) -> List[RecommendedAction]:
    actions = []
    if anomalies:
        actions.append(
            RecommendedAction(
                priority=1,
                title="Đối chiếu nhật ký tại kỳ bất thường",
                description=(
                    "Kiểm tra ca sản xuất, thiết bị hoạt động, thời gian dừng máy và "
                    "sự cố tại đúng các mốc AI đã đánh dấu."
                ),
                verification_metric="Giải thích được nguyên nhân cho từng kỳ bất thường",
            )
        )

        if normalized_by == "production_units":
            actions.append(
                RecommendedAction(
                    priority=2,
                    title="Kiểm tra thiết bị chạy không tải",
                    description=(
                        "Đo các phụ tải chính ngoài thời gian tạo sản phẩm và so sánh "
                        "kWh trên mỗi đơn vị trước, sau điều chỉnh."
                    ),
                    verification_metric="kWh/đơn vị sản phẩm giảm về gần đường cơ sở",
                )
            )
        elif normalized_by == "operating_hours":
            actions.append(
                RecommendedAction(
                    priority=2,
                    title="Rà soát phụ tải theo giờ hoạt động",
                    description=(
                        "Kiểm tra thiết bị quá tải, thiết bị phụ và chế độ vận hành "
                        "trong các giờ có mức điện cao."
                    ),
                    verification_metric="kWh/giờ vận hành giảm về gần đường cơ sở",
                )
            )
        else:
            actions.append(
                RecommendedAction(
                    priority=2,
                    title="Bổ sung sản lượng hoặc giờ vận hành",
                    description=(
                        "Ghi thêm biến hoạt động theo cùng mốc thời gian để AI phân biệt "
                        "tăng điện hợp lý với suy giảm hiệu suất."
                    ),
                    verification_metric="Tối thiểu 7 kỳ có dữ liệu chuẩn hóa đầy đủ",
                )
            )

    if trend is not None and trend >= 10:
        actions.append(
            RecommendedAction(
                priority=len(actions) + 1,
                title="Lập kiểm tra bảo trì theo xu hướng",
                description=(
                    "Rà soát vệ sinh, hiệu chỉnh và tình trạng tải của các thiết bị "
                    "tiêu thụ điện lớn."
                ),
                verification_metric="Xu hướng 7 kỳ tiếp theo không còn tăng trên 10%",
            )
        )

    if not actions:
        actions.append(
            RecommendedAction(
                priority=1,
                title="Tiếp tục duy trì đo lường",
                description=(
                    "Duy trì nhập số đo cùng sản lượng hoặc giờ vận hành để tăng độ "
                    "tin cậy và phát hiện sớm thay đổi."
                ),
                verification_metric="Có ít nhất 30 kỳ dữ liệu liên tục",
            )
        )

    return actions


def analyze_time_series(
    data: EnergyTimeSeriesInput,
) -> TimeSeriesAnalysisResponse:
    points = sorted(data.points, key=lambda point: point.timestamp)
    normalized_by, metric_unit, values = _select_metric(points)
    baseline_metric = median(values)
    absolute_deviations = [abs(value - baseline_metric) for value in values]
    median_absolute_deviation = median(absolute_deviations)
    trend = _trend_percent(values)
    anomalies = []

    for point, value in zip(points, values):
        if baseline_metric == 0:
            continue

        deviation_percent = (
            (value - baseline_metric) / baseline_metric * 100
        )
        robust_z = (
            0.6745 * (value - baseline_metric) / median_absolute_deviation
            if median_absolute_deviation > 0
            else float("inf") if value > baseline_metric else 0
        )

        if (
            deviation_percent < MINIMUM_DEVIATION_PERCENT
            or robust_z < ROBUST_Z_THRESHOLD
        ):
            continue

        expected_kwh = _expected_consumption(
            point,
            baseline_metric,
            normalized_by,
        )
        excess_kwh = max(point.consumption_kwh - expected_kwh, 0)
        anomalies.append(
            EnergyAnomaly(
                timestamp=point.timestamp,
                actual_kwh=round(point.consumption_kwh, 2),
                expected_kwh=round(expected_kwh, 2),
                excess_kwh=round(excess_kwh, 2),
                deviation_percent=round(deviation_percent, 1),
                severity=round(min(deviation_percent / 100, 1), 2),
                reason=(
                    f"Mức tiêu thụ chuẩn hóa cao hơn đường cơ sở "
                    f"{deviation_percent:.1f}%."
                ),
            )
        )

    confidence = _confidence(len(points), normalized_by)
    opportunities = []

    if anomalies:
        opportunities.append(
            Opportunity(
                facility=data.facility_name,
                category="energy",
                problem_type="abnormal_energy_consumption",
                severity=max(anomaly.severity for anomaly in anomalies),
                confidence=confidence,
                evidence={
                    "anomaly_count": len(anomalies),
                    "total_excess_kwh": round(
                        sum(anomaly.excess_kwh for anomaly in anomalies),
                        2,
                    ),
                    "normalized_by": normalized_by,
                },
            )
        )

    if trend is not None and trend >= 10:
        opportunities.append(
            Opportunity(
                facility=data.facility_name,
                category="energy",
                problem_type="rising_energy_baseline",
                severity=round(min(trend / 50, 1), 2),
                confidence=confidence,
                evidence={
                    "recent_7_period_trend_percent": trend,
                    "normalized_by": normalized_by,
                },
            )
        )

    next_questions = []
    if normalized_by == "consumption":
        next_questions.extend(
            [
                "Có dữ liệu sản lượng tương ứng với từng kỳ không?",
                "Có dữ liệu số giờ vận hành tương ứng với từng kỳ không?",
            ]
        )
    if anomalies:
        next_questions.append(
            "Thiết bị hoặc ca sản xuất nào hoạt động tại các thời điểm bất thường?"
        )

    summary = _build_summary(anomalies, len(points))
    diagnoses = _build_diagnoses(
        normalized_by,
        anomalies,
        trend,
        confidence,
    )
    recommended_actions = _build_actions(
        normalized_by,
        anomalies,
        trend,
    )

    return TimeSeriesAnalysisResponse(
        engine_version=ENGINE_VERSION,
        facility=data.facility_name,
        interval=data.interval,
        confidence=confidence,
        baseline=EnergyBaseline(
            normalized_by=normalized_by,
            metric_unit=metric_unit,
            median=round(baseline_metric, 4),
            average=round(mean(values), 4),
            minimum=round(min(values), 4),
            maximum=round(max(values), 4),
            trend_percent=trend,
        ),
        summary=summary,
        anomalies=anomalies,
        opportunities=opportunities,
        diagnoses=diagnoses,
        recommended_actions=recommended_actions,
        next_questions=next_questions,
    )
