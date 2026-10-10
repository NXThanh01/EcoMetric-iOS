import uuid
from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, Field

from schemas import TimeSeriesAnalysisResponse


class GeminiRootCause(BaseModel):
    title: str = Field(min_length=1, max_length=160)
    explanation: str = Field(min_length=1, max_length=800)
    evidence: List[str] = Field(min_length=1, max_length=5)
    confidence_reason: str = Field(min_length=1, max_length=300)


class GeminiRecommendation(BaseModel):
    priority: int = Field(ge=1, le=5)
    title: str = Field(min_length=1, max_length=160)
    steps: List[str] = Field(min_length=1, max_length=5)
    expected_outcome: str = Field(min_length=1, max_length=400)
    verification_metric: str = Field(min_length=1, max_length=300)


class GeminiNarrative(BaseModel):
    headline: str = Field(min_length=1, max_length=180)
    executive_summary: str = Field(min_length=1, max_length=1200)
    root_causes: List[GeminiRootCause] = Field(default_factory=list, max_length=3)
    recommendations: List[GeminiRecommendation] = Field(
        min_length=1,
        max_length=5,
    )
    caveats: List[str] = Field(default_factory=list, max_length=5)
    follow_up_questions: List[str] = Field(default_factory=list, max_length=5)


class GeminiDatasetInsightResponse(BaseModel):
    provider: Literal["gemini"] = "gemini"
    model: str
    generated_at: datetime
    dataset_id: uuid.UUID
    facility: str
    quantitative_analysis: TimeSeriesAnalysisResponse
    insight: GeminiNarrative


class AdvisorHistoryMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=2_000)


class DatasetAdvisorRequest(BaseModel):
    question: str = Field(min_length=2, max_length=1_000)
    history: List[AdvisorHistoryMessage] = Field(default_factory=list, max_length=8)


class DatasetAdvisorAnswer(BaseModel):
    answer: str = Field(min_length=1, max_length=2_000)
    evidence: List[str] = Field(default_factory=list, max_length=5)
    suggested_actions: List[str] = Field(default_factory=list, max_length=5)
    verification_metric: Optional[str] = Field(default=None, max_length=300)
    follow_up_questions: List[str] = Field(default_factory=list, max_length=3)


class DatasetAdvisorResponse(BaseModel):
    provider: Literal["gemini"] = "gemini"
    model: str
    dataset_id: uuid.UUID
    answer: DatasetAdvisorAnswer
