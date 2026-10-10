from schemas import DataQuality, EnergyInput


def assess_data_quality(data: EnergyInput, assumptions: list[str]) -> DataQuality:
    """Đánh giá độ tin cậy của đầu vào trước khi xếp hạng giải pháp."""
    source_scores = {
        "measured": 0.95,
        "estimated": 0.80,
        "demo": 0.65,
    }
    score = source_scores[data.data_source]
    missing_fields = []

    if data.data_source == "measured":
        if data.measurement_days is None:
            missing_fields.append("measurement_days")
            score -= 0.10
        elif data.measurement_days < 7:
            score -= 0.10

    if assumptions:
        score = min(score, 0.75)

    return DataQuality(
        score=round(max(score, 0), 2),
        missing_fields=missing_fields,
        assumptions=assumptions,
    )
