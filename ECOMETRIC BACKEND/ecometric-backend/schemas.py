from datetime import datetime
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
    data_source: Literal["measured", "estimated", "demo"] = "estimated"
    measurement_days: Optional[int] = Field(default=None, ge=1, le=366)


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


class EnergyTimeSeriesPoint(BaseModel):
    timestamp: datetime
    consumption_kwh: float = Field(ge=0)
    production_units: Optional[float] = Field(default=None, gt=0)
    operating_hours: Optional[float] = Field(default=None, gt=0, le=24)


class EnergyTimeSeriesInput(BaseModel):
    facility_name: str = Field(min_length=1, max_length=200)
    interval: Literal["hourly", "daily", "monthly"] = "daily"
    points: List[EnergyTimeSeriesPoint] = Field(
        min_length=7,
        max_length=10_000,
    )


class EnergyAnomaly(BaseModel):
    timestamp: datetime
    actual_kwh: float
    expected_kwh: float
    excess_kwh: float
    deviation_percent: float
    severity: float = Field(ge=0, le=1)
    reason: str


class EnergyBaseline(BaseModel):
    normalized_by: Literal[
        "consumption",
        "production_units",
        "operating_hours",
    ]
    metric_unit: str
    median: float
    average: float
    minimum: float
    maximum: float
    trend_percent: Optional[float] = None


class EnergyInsightSummary(BaseModel):
    status: Literal["normal", "attention", "critical"]
    total_excess_kwh: float = Field(ge=0)
    anomaly_rate_percent: float = Field(ge=0, le=100)
    message: str


class RootCauseHypothesis(BaseModel):
    code: str
    title: str
    description: str
    confidence: float = Field(ge=0, le=1)
    evidence: List[str] = Field(default_factory=list)


class RecommendedAction(BaseModel):
    priority: int = Field(ge=1)
    title: str
    description: str
    verification_metric: str


class TimeSeriesAnalysisResponse(BaseModel):
    engine_version: str
    facility: str
    interval: str
    confidence: float = Field(ge=0, le=1)
    baseline: EnergyBaseline
    summary: EnergyInsightSummary
    anomalies: List[EnergyAnomaly]
    opportunities: List[Opportunity]
    diagnoses: List[RootCauseHypothesis]
    recommended_actions: List[RecommendedAction]
    next_questions: List[str]


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


class ApplicabilityAssessment(BaseModel):
    eligible: bool
    score: float = Field(ge=0, le=1)
    passed_rules: List[str] = Field(default_factory=list)
    failed_rules: List[str] = Field(default_factory=list)


class SavingsScenario(BaseModel):
    energy_saving_kwh_month: float
    cost_saving_vnd_month: float
    cost_saving_vnd_year: float
    payback_months: float


class SavingsScenarios(BaseModel):
    conservative: SavingsScenario
    expected: SavingsScenario
    optimistic: SavingsScenario


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
    scenarios: SavingsScenarios
    applicability: ApplicabilityAssessment
    ranking: RecommendationRanking
    data_quality: DataQuality
    source: RecommendationSource
    explanation: str
    rationale: List[str]
    verification_plan: List[str]


class RecommendationListResponse(BaseModel):
    engine_version: str
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
