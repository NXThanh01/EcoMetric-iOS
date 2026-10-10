import uuid
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field


UserRole = Literal["owner", "admin", "member"]


class OrganizationBootstrapRequest(BaseModel):
    company_name: str = Field(min_length=2, max_length=200)
    owner_name: str = Field(min_length=2, max_length=160)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    otp: str = Field(pattern=r"^\d{6}$")


class RegistrationOTPRequest(BaseModel):
    email: EmailStr


class RegistrationOTPResponse(BaseModel):
    message: str
    expires_in_seconds: int
    resend_after_seconds: int
    development_code: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class OrganizationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    plan_code: str
    subscription_status: str
    seat_limit: int


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    organization_id: uuid.UUID
    email: str
    full_name: str
    role: UserRole
    is_active: bool
    must_change_password: bool
    created_at: datetime


class AuthResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    user: UserResponse
    organization: OrganizationResponse


class AccountContextResponse(BaseModel):
    user: UserResponse
    organization: OrganizationResponse


class MemberCreate(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=160)
    password: str = Field(min_length=8, max_length=128)
    role: Literal["admin", "member"] = "member"


class MemberUpdate(BaseModel):
    role: Optional[Literal["admin", "member"]] = None
    is_active: Optional[bool] = None


class PasswordChangeRequest(BaseModel):
    current_password: str = Field(min_length=8, max_length=128)
    new_password: str = Field(min_length=8, max_length=128)


class MessageResponse(BaseModel):
    message: str
