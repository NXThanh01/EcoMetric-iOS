from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel, Field


class EnergyInput(BaseModel):
    facility_name: str = Field(min_length=1, max_length=200)
    problem_type: str = Field(
        default="lighting_high_consumption",
        min_length=1,
        max_length=100,
    )
    lamp_quantity: int = Field(gt=0)
    current_power_w: float = Field(gt=0)
    proposed_power_w: float = Field(gt=0)
    hours_per_day: float = Field(gt=0, le=24)
    days_per_month: float = Field(gt=0, le=31)
    electricity_price_vnd_per_kwh: float = Field(gt=0)
    investment_vnd: float = Field(ge=0)


class Opportunity(BaseModel):
    facility: str
    category: str
    problem_type: str
    severity: float = Field(ge=0, le=1)
    confidence: float = Field(ge=0, le=1)
    evidence: Dict[str, Any]


class AnalysisResponse(BaseModel):
    facility: str
    opportunities: List[Opportunity]


class RecommendationSource(BaseModel):
    organization: Optional[str] = None
    document_title: Optional[str] = None
    year: Optional[int] = None
    url: Optional[str] = None
    verified: bool = False


class RecommendationImpact(BaseModel):
    energy_saving_kwh_month: float
    cost_saving_vnd_month: float
    cost_saving_vnd_year: float
    investment_vnd: float
    payback_months: float
    co2_reduction: Optional[float] = None
    co2_status: str = "Chờ xác nhận hệ số phát thải điện"


class RecommendationRanking(BaseModel):
    score: float = Field(ge=0, le=100)
    priority: Literal["high", "medium", "low"]
    components: Dict[str, float]


class DataQuality(BaseModel):
    score: float = Field(ge=0, le=1)
    missing_fields: List[str] = Field(default_factory=list)
    assumptions: List[str] = Field(default_factory=list)


class RecommendationItem(BaseModel):
    recommendation_id: str
    facility: str
    problem_type: str
    problem: str
    knowledge_id: str
    knowledge_category: str
    knowledge_description: str
    solution: str
    implementation_steps: List[str]
    impact: RecommendationImpact
    ranking: RecommendationRanking
    data_quality: DataQuality
    source: RecommendationSource
    explanation: str


class RecommendationListResponse(BaseModel):
    facility: str
    opportunity: Opportunity
    recommendations: List[RecommendationItem]


# Phản hồi tương thích ngược dành cho ứng dụng iOS hiện tại.
class RecommendationResponse(BaseModel):
    facility: str
    problem: str
    solution: str
    knowledge_id: str
    knowledge_category: str
    knowledge_description: str
    implementation_steps: List[str]
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
