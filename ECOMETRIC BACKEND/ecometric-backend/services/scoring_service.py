from schemas import (
    RecommendationImpact,
    RecommendationRanking,
)


def score_recommendation(
    impact: RecommendationImpact,
    confidence: float,
    source_verified: bool,
    applicability: float,
) -> RecommendationRanking:
    financial_impact = min(
        impact.cost_saving_vnd_year / 30_000_000,
        1,
    ) * 100

    if impact.payback_months == 0:
        payback = 100
    else:
        payback = max(
            0,
            min(100, (24 - impact.payback_months) / 24 * 100),
        )

    components = {
        "financial_impact": round(financial_impact, 1),
        "payback": round(payback, 1),
        "applicability": round(applicability * 100, 1),
        "data_confidence": round(confidence * 100, 1),
        "source_quality": 100 if source_verified else 30,
    }

    score = (
        components["financial_impact"] * 0.30
        + components["payback"] * 0.25
        + components["applicability"] * 0.20
        + components["data_confidence"] * 0.15
        + components["source_quality"] * 0.10
    )

    if score >= 80:
        priority = "high"
    elif score >= 60:
        priority = "medium"
    else:
        priority = "low"

    return RecommendationRanking(
        score=round(score, 1),
        priority=priority,
        components=components,
    )
