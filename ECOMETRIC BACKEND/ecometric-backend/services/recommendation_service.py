import re
from typing import List

from fastapi import HTTPException

from schemas import (
    EnergyInput,
    RecommendationItem,
    RecommendationListResponse,
    RecommendationSource,
)
from services.applicability_service import assess_applicability
from services.calculators import CALCULATORS
from services.data_quality_service import assess_data_quality
from services.knowledge_service import find_solutions
from services.opportunity_service import analyze_energy_input
from services.scenario_service import build_scenarios
from services.scoring_service import score_recommendation


ENGINE_VERSION = "1.0.0"


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
    if data.proposed_power_w >= data.current_power_w:
        raise HTTPException(
            status_code=422,
            detail="Proposed lamp power must be lower than current lamp power",
        )

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

        applicability = assess_applicability(data, knowledge)
        if not applicability.eligible:
            continue

        impact = calculator(data, knowledge)
        scenarios = build_scenarios(impact, knowledge)
        source = _source_from_knowledge(knowledge)
        assumptions = _assumptions(knowledge)
        data_quality = assess_data_quality(data, assumptions)

        ranking = score_recommendation(
            impact=impact,
            confidence=data_quality.score,
            source_verified=source.verified,
            applicability=applicability.score,
        )
        priority_label = {
            "high": "cao",
            "medium": "trung bình",
            "low": "thấp",
        }[ranking.priority]

        explanation = (
            f"Giải pháp dự kiến tiết kiệm "
            f"{scenarios.expected.energy_saving_kwh_month:.0f} kWh/tháng. "
            f"Khoảng tiết kiệm thận trọng đến lạc quan là "
            f"{scenarios.conservative.cost_saving_vnd_year:,.0f}–"
            f"{scenarios.optimistic.cost_saving_vnd_year:,.0f} VNĐ/năm. "
            f"Mức ưu tiên: {priority_label}."
        )

        if impact.investment_vnd == 0:
            payback_rationale = "Giải pháp không yêu cầu vốn đầu tư trong mô hình hiện tại."
        else:
            payback_rationale = (
                f"Thời gian hoàn vốn kỳ vọng "
                f"{impact.payback_months:.1f} tháng."
            )

        rationale = [
            *applicability.passed_rules,
            payback_rationale,
            (
                "Nguồn kiến thức đã được xác minh."
                if source.verified
                else "Nguồn kiến thức chưa được xác minh."
            ),
        ]

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
                scenarios=scenarios,
                applicability=applicability,
                ranking=ranking,
                data_quality=data_quality,
                source=source,
                explanation=explanation,
                rationale=rationale,
                verification_plan=knowledge.get(
                    "verification_plan",
                    ["Đo lại dữ liệu sau triển khai và so sánh với đường cơ sở."],
                ),
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
        engine_version=ENGINE_VERSION,
        facility=data.facility_name,
        opportunity=opportunity,
        recommendations=recommendations,
    )
