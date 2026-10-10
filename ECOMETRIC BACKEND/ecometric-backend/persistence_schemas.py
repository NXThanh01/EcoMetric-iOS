import uuid
from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from schemas import EnergyTimeSeriesPoint


class FacilityCreate(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    timezone: str = Field(default="Asia/Ho_Chi_Minh", min_length=1, max_length=64)


class FacilityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    timezone: str
    created_at: datetime


class ElectricityDatasetCreate(BaseModel):
    facility_id: uuid.UUID
    meter_name: str = Field(default="Điện tổng", min_length=1, max_length=200)
    source_type: Literal["manual", "csv", "api", "meter"] = "manual"
    interval: Literal["hourly", "daily", "monthly"] = "daily"
    operational_context: Optional[str] = Field(default=None, max_length=2_000)
    desired_outcome: Optional[str] = Field(default=None, max_length=1_000)
    points: List[EnergyTimeSeriesPoint] = Field(min_length=1, max_length=10_000)

    @model_validator(mode="after")
    def validate_unique_timestamps(self):
        timestamps = [point.timestamp for point in self.points]
        if len(timestamps) != len(set(timestamps)):
            raise ValueError("Các mốc thời gian trong một bộ dữ liệu không được trùng nhau")
        return self


class DatasetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    facility_id: uuid.UUID
    meter_id: Optional[uuid.UUID]
    source_type: str
    interval: str
    status: str
    operational_context: Optional[str]
    desired_outcome: Optional[str]
    record_count: int
    period_start: Optional[datetime]
    period_end: Optional[datetime]
    created_at: datetime


class MeasurementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    dataset_id: uuid.UUID
    timestamp: datetime
    consumption_kwh: float
    production_units: Optional[float]
    operating_hours: Optional[float]


class DatasetDetailResponse(DatasetResponse):
    facility_name: str
    meter_name: Optional[str]
