from typing import Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from services.knowledge_service import find_solution


app = FastAPI(
    title="EcoMetric API",
    description="Knowledge base and calculation engine for EcoMetric.",
    version="0.4.0",
)


# ======================================================
# INPUT MODEL
# ======================================================

class EnergyInput(BaseModel):
    facility_name: str = Field(min_length=1, max_length=200)
    problem_type: str = Field(min_length=1, max_length=100)
    lamp_quantity: int = Field(gt=0)
    current_power_w: float = Field(gt=0)
    proposed_power_w: float = Field(gt=0)
    hours_per_day: float = Field(gt=0, le=24)
    days_per_month: float = Field(gt=0, le=31)
    electricity_price_vnd_per_kwh: float = Field(gt=0)
    investment_vnd: float = Field(ge=0)


class RecommendationSource(BaseModel):
    organization: Optional[str] = None
    document_title: Optional[str] = None
    year: Optional[int] = None
    url: Optional[str] = None
    verified: bool = False


class RecommendationResponse(BaseModel):
    facility: str
    problem: str
    solution: str
    knowledge_id: str
    knowledge_category: str
    knowledge_description: str
    implementation_steps: list[str]
    energy_saving_kwh_month: float
    cost_saving_vnd_month: float
    cost_saving_vnd_year: float
    investment_vnd: float
    payback_months: float
    co2_reduction: Optional[float]
    co2_status: str
    emission_factor_verified: bool
    data_origin: str
    source: RecommendationSource


# ======================================================
# BASIC ROUTES
# ======================================================

@app.get("/")
def root():
    return {
        "app": "EcoMetric",
        "version": app.version,
        "status": "Backend is running",
    }


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


# ======================================================
# KNOWLEDGE BASE TEST
# ======================================================

@app.get("/knowledge/led")
def get_led_knowledge():

    knowledge = find_solution(
        category="energy",
        problem="lighting_high_consumption"
    )

    if not knowledge:
        raise HTTPException(status_code=404, detail="Solution not found")

    return knowledge


# ======================================================
# RECOMMENDATION
# ======================================================

@app.post("/recommend", response_model=RecommendationResponse)
def recommend(data: EnergyInput) -> RecommendationResponse:

    # 1. RETRIEVE KNOWLEDGE

    knowledge = find_solution(
        category="energy",
        problem=data.problem_type,
    )

    if not knowledge:
        raise HTTPException(status_code=404, detail="Solution not found")

    if data.problem_type != "lighting_high_consumption":
        raise HTTPException(
            status_code=422,
            detail="Calculation engine is not available for this problem type",
        )

    # ==================================================
    # 2. CALCULATION ENGINE
    # ==================================================

    power_reduction_w = (
        data.current_power_w
        - data.proposed_power_w
    )

    if power_reduction_w <= 0:
        raise HTTPException(
            status_code=422,
            detail="Proposed lamp power must be lower than current lamp power",
        )

    energy_saving_kwh_month = (
        data.lamp_quantity
        * power_reduction_w
        * data.hours_per_day
        * data.days_per_month
        / 1000
    )

    cost_saving_vnd_month = (
        energy_saving_kwh_month
        * data.electricity_price_vnd_per_kwh
    )

    cost_saving_vnd_year = (
        cost_saving_vnd_month
        * 12
    )

    payback_months = (
        data.investment_vnd
        / cost_saving_vnd_month
        if cost_saving_vnd_month > 0
        else 0
    )

    # ==================================================
    # 3. SOURCE METADATA
    # ==================================================

    source = knowledge.get(
        "source",
        {}
    )

    # The knowledge source validates the intervention, not a grid emission
    # factor. CO2 remains unavailable until a dedicated factor is supplied.
    emission_factor_verified = False

    # ==================================================
    # 4. RESPONSE
    # ==================================================

    return RecommendationResponse(

        facility=data.facility_name,

        problem=knowledge["title"],

        solution=(
            f"Thay {data.lamp_quantity} bóng "
            f"{data.current_power_w:.0f}W "
            f"bằng LED {data.proposed_power_w:.0f}W"
        ),

        knowledge_id=knowledge["id"],

        knowledge_category=knowledge["category"],

        knowledge_description=knowledge["description"],

        implementation_steps=knowledge["implementation_steps"],

        energy_saving_kwh_month=round(energy_saving_kwh_month, 2),

        cost_saving_vnd_month=round(cost_saving_vnd_month, 0),

        cost_saving_vnd_year=round(cost_saving_vnd_year, 0),

        investment_vnd=data.investment_vnd,

        payback_months=round(payback_months, 1),

        co2_reduction=None,

        co2_status="Chờ xác nhận hệ số phát thải điện",
        emission_factor_verified=emission_factor_verified,

        data_origin="Dữ liệu minh họa",

        source=RecommendationSource(
            organization=source.get("organization"),
            document_title=source.get("document_title"),
            year=source.get("year"),
            url=source.get("url"),
            verified=source.get("verified", False),
        ),
    )
