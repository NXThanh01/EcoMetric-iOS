import re
from typing import List

from fastapi import HTTPException

from schemas import (
    DataQuality,
    EnergyInput,
    RecommendationItem,
    RecommendationListResponse,
    RecommendationSource,
)
from services.calculators import CALCULATORS
from services.knowledge_service import find_solutions
from services.opportunity_service import analyze_energy_input
from services.scoring_service import score_recommendation


def _source_from_knowledge(knowledge: dict) -> RecommendationSource:
    source = knowledge.get("source", {})
    return RecommendationSource(
        organization=source.get("organization"),
        document_title=source.get("document_title"),
        year=source.get("year"),
        url=source.get("url"),
        verified=source.get("verified", False),
    )


def _solution_title(data: EnergyInput, knowledge: dict) -> str:
    if knowledge.get("calculator") == "lighting_replacement":
        return (
            f"Thay {data.lamp_quantity} bóng "
            f"{data.current_power_w:.0f}W bằng LED "
            f"{data.proposed_power_w:.0f}W"
        )
    return knowledge["title"]


def _recommendation_id(facility: str, knowledge_id: str) -> str:
    facility_slug = re.sub(
        r"[^a-z0-9]+",
        "-",
        facility.lower(),
    ).strip("-") or "facility"
    return f"{facility_slug}:{knowledge_id}"


def _assumptions(knowledge: dict) -> List[str]:
    result = []
    for key, value in knowledge.get("assumptions", {}).items():
        result.append(f"{key}={value}")
    return result


def build_recommendations(
    data: EnergyInput,
) -> RecommendationListResponse:
    opportunity = analyze_energy_input(data)
    knowledge_records = find_solutions(
        category=opportunity.category,
        problem=opportunity.problem_type,
    )

    if not knowledge_records:
        raise HTTPException(
            status_code=404,
            detail="No recommendation knowledge found for this problem",
        )

    recommendations = []
    for knowledge in knowledge_records:
        calculator_name = knowledge.get("calculator")
        calculator = CALCULATORS.get(calculator_name)
        if calculator is None:
            continue

        impact = calculator(data, knowledge)
        source = _source_from_knowledge(knowledge)
        applicability = float(knowledge.get("applicability_score", 1))
        data_confidence = opportunity.confidence
        assumptions = _assumptions(knowledge)

        if assumptions:
            data_confidence = min(data_confidence, 0.75)

        ranking = score_recommendation(
            impact=impact,
            confidence=data_confidence,
            source_verified=source.verified,
            applicability=applicability,
        )

        explanation = (
            f"Giải pháp có thể tiết kiệm khoảng "
            f"{impact.energy_saving_kwh_month:.0f} kWh/tháng, "
            f"tương đương {impact.cost_saving_vnd_year:,.0f} VNĐ/năm. "
            f"Mức ưu tiên: {ranking.priority}."
        )

        recommendations.append(
            RecommendationItem(
                recommendation_id=_recommendation_id(
                    data.facility_name,
                    knowledge["id"],
                ),
                facility=data.facility_name,
                problem_type=opportunity.problem_type,
                problem=knowledge["title"],
                knowledge_id=knowledge["id"],
                knowledge_category=knowledge["category"],
                knowledge_description=knowledge["description"],
                solution=_solution_title(data, knowledge),
                implementation_steps=knowledge["implementation_steps"],
                impact=impact,
                ranking=ranking,
                data_quality=DataQuality(
                    score=data_confidence,
                    assumptions=assumptions,
                ),
                source=source,
                explanation=explanation,
            )
        )

    if not recommendations:
        raise HTTPException(
            status_code=422,
            detail="No calculation engine is available for this problem",
        )

    recommendations.sort(
        key=lambda item: item.ranking.score,
        reverse=True,
    )

    return RecommendationListResponse(
        facility=data.facility_name,
        opportunity=opportunity,
        recommendations=recommendations,
    )
