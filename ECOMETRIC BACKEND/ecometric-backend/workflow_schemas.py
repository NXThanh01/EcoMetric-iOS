import uuid
from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field, model_validator


class ActionCreate(BaseModel):
    title: str = Field(min_length=1, max_length=160)
    verification_metric: str = Field(min_length=1, max_length=300)
    assignee_email: Optional[EmailStr] = None
    due_date: Optional[datetime] = None


class ActionUpdate(BaseModel):
    status: Literal["planned", "in_progress", "completed"]
    assignee_email: Optional[EmailStr] = None
    due_date: Optional[datetime] = None
    notes: str = Field(default="", max_length=2000)


class ActionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    dataset_id: uuid.UUID
    title: str
    verification_metric: str
    assignee_email: Optional[str]
    due_date: Optional[datetime]
    status: str
    notes: str
    created_at: datetime


class ImpactRequest(BaseModel):
    after_dataset_id: uuid.UUID
    electricity_price_vnd: Optional[float] = Field(default=None, ge=0, le=100000, allow_inf_nan=False)
    investment_vnd: Optional[float] = Field(default=None, ge=0, le=1e15, allow_inf_nan=False)
    emission_factor_kg_per_kwh: Optional[float] = Field(default=None, ge=0, le=10, allow_inf_nan=False)
    factor_source: Optional[str] = Field(default=None, max_length=500)

    @model_validator(mode="after")
    def require_source(self):
        if self.emission_factor_kg_per_kwh is not None and not (self.factor_source or "").strip():
            raise ValueError("Cần nguồn và năm áp dụng của hệ số phát thải")
        return self
