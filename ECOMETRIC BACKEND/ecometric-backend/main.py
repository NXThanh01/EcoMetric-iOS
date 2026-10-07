from fastapi import FastAPI, HTTPException

from schemas import (
    AnalysisResponse,
    EnergyInput,
    RecommendationListResponse,
    RecommendationResponse,
)
from services.knowledge_service import find_solution
from services.opportunity_service import analyze_energy_input
from services.recommendation_service import build_recommendations


app = FastAPI(
    title="EcoMetric API",
    description=(
        "Opportunity detection, knowledge retrieval, scoring, and "
        "calculation engine for EcoMetric."
    ),
    version="0.5.0",
)


@app.get("/")
def root():
    return {
        "app": "EcoMetric",
        "version": app.version,
        "status": "Backend is running",
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/knowledge/led")
def get_led_knowledge():
    knowledge = find_solution(
        category="energy",
        problem="lighting_high_consumption",
    )
    if not knowledge:
        raise HTTPException(status_code=404, detail="Solution not found")
    return knowledge


@app.post("/analyze", response_model=AnalysisResponse)
def analyze(data: EnergyInput) -> AnalysisResponse:
    opportunity = analyze_energy_input(data)
    return AnalysisResponse(
        facility=data.facility_name,
        opportunities=[opportunity],
    )


@app.post(
    "/recommendations",
    response_model=RecommendationListResponse,
)
def recommendations(data: EnergyInput) -> RecommendationListResponse:
    return build_recommendations(data)


@app.post("/recommend", response_model=RecommendationResponse)
def recommend(data: EnergyInput) -> RecommendationResponse:
    """Return the highest-ranked recommendation for the current iOS app."""
    result = build_recommendations(data)
    top = result.recommendations[0]

    return RecommendationResponse(
        facility=top.facility,
        problem=top.problem,
        solution=top.solution,
        knowledge_id=top.knowledge_id,
        knowledge_category=top.knowledge_category,
        knowledge_description=top.knowledge_description,
        implementation_steps=top.implementation_steps,
        energy_saving_kwh_month=top.impact.energy_saving_kwh_month,
        cost_saving_vnd_month=top.impact.cost_saving_vnd_month,
        cost_saving_vnd_year=top.impact.cost_saving_vnd_year,
        investment_vnd=top.impact.investment_vnd,
        payback_months=top.impact.payback_months,
        co2_reduction=top.impact.co2_reduction,
        co2_status=top.impact.co2_status,
        emission_factor_verified=False,
        data_origin="Dữ liệu minh họa",
        source=top.source,
    )
