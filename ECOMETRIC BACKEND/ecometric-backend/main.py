import uuid

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from database import get_db
from auth_schemas import (
    AccountContextResponse,
    AuthResponse,
    LoginRequest,
    MemberCreate,
    MemberUpdate,
    MessageResponse,
    OrganizationBootstrapRequest,
    PasswordChangeRequest,
    RegistrationOTPRequest,
    RegistrationOTPResponse,
    UserResponse,
)
from db_models import User
from gemini_schemas import GeminiDatasetInsightResponse
from persistence_schemas import (
    DatasetDetailResponse,
    DatasetResponse,
    ElectricityDatasetCreate,
    FacilityCreate,
    FacilityResponse,
    MeasurementResponse,
)

from schemas import (
    AnalysisResponse,
    EnergyInput,
    EnergyTimeSeriesInput,
    RecommendationListResponse,
    RecommendationResponse,
    TimeSeriesAnalysisResponse,
)
from services.knowledge_service import find_solution
from services.opportunity_service import analyze_energy_input
from services.recommendation_service import (
    ENGINE_VERSION as RECOMMENDATION_ENGINE_VERSION,
    build_recommendations,
)
from services.time_series_service import (
    ENGINE_VERSION as TIME_SERIES_ENGINE_VERSION,
    analyze_time_series,
)
from services.data_store_service import (
    ResourceConflictError,
    ResourceNotFoundError,
    build_time_series_input,
    create_electricity_dataset,
    create_facility,
    get_dataset,
    list_facilities,
    list_measurements,
)
from services.gemini_insight_service import (
    GeminiGenerationError,
    GeminiInsightService,
    GeminiNotConfiguredError,
)
from services.auth_service import (
    AccountConflictError,
    AuthenticationError,
    AuthorizationError,
    OTPRateLimitError,
    OTPVerificationError,
    bootstrap_organization,
    change_password,
    create_member,
    get_user_by_token,
    list_members,
    login,
    logout,
    request_registration_otp,
    update_member,
)
from services.email_service import EmailDeliveryError
from settings import get_settings


app = FastAPI(
    title="EcoMetric API",
    description=(
        "Time-series anomaly detection, knowledge retrieval, scoring, "
        "and calculation engine for EcoMetric."
    ),
    version="1.2.0",
)

bearer_scheme = HTTPBearer(auto_error=False)


def current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Vui lòng đăng nhập")
    try:
        return get_user_by_token(db, credentials.credentials)
    except AuthenticationError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error


def bearer_token(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> str:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Vui lòng đăng nhập")
    return credentials.credentials


def ready_user(user: User = Depends(current_user)) -> User:
    if user.must_change_password:
        raise HTTPException(
            status_code=403,
            detail="Vui lòng đổi mật khẩu tạm trước khi sử dụng EcoMetric",
        )
    return user


@app.get("/")
def root():
    return {
        "app": "EcoMetric",
        "version": app.version,
        "status": "Backend is running",
    }


@app.get("/health")
def health(db: Session = Depends(get_db)):
    settings = get_settings()
    database_status = "ok"
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError:
        database_status = "unavailable"

    return {
        "status": "ok",
        "database": database_status,
        "gemini": "configured" if settings.gemini_api_key else "not_configured",
        "gemini_model": settings.gemini_model,
        "gemini_fallback_model": settings.gemini_fallback_model,
        "email_delivery": settings.email_delivery_mode,
        "api_version": app.version,
        "recommendation_engine_version": RECOMMENDATION_ENGINE_VERSION,
        "time_series_engine_version": TIME_SERIES_ENGINE_VERSION,
    }


@app.post(
    "/v1/auth/registration-otp",
    response_model=RegistrationOTPResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
def send_registration_code(
    data: RegistrationOTPRequest,
    db: Session = Depends(get_db),
) -> RegistrationOTPResponse:
    try:
        result = request_registration_otp(db, str(data.email))
        return RegistrationOTPResponse(
            message="Mã xác minh đã được gửi tới email của bạn",
            expires_in_seconds=result.expires_in_seconds,
            resend_after_seconds=result.resend_after_seconds,
            development_code=result.development_code,
        )
    except AccountConflictError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error
    except OTPRateLimitError as error:
        raise HTTPException(status_code=429, detail=str(error)) from error
    except EmailDeliveryError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error


@app.post(
    "/v1/auth/register-company",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_company(
    data: OrganizationBootstrapRequest,
    db: Session = Depends(get_db),
) -> AuthResponse:
    try:
        return bootstrap_organization(db, data)
    except AccountConflictError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error
    except OTPVerificationError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@app.post("/v1/auth/login", response_model=AuthResponse)
def login_account(
    data: LoginRequest,
    db: Session = Depends(get_db),
) -> AuthResponse:
    try:
        return login(db, data)
    except AuthenticationError as error:
        raise HTTPException(status_code=401, detail=str(error)) from error


@app.get("/v1/auth/me", response_model=AccountContextResponse)
def get_current_account(user: User = Depends(current_user)) -> AccountContextResponse:
    return AccountContextResponse(user=user, organization=user.organization)


@app.post("/v1/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout_account(
    token: str = Depends(bearer_token),
    db: Session = Depends(get_db),
) -> None:
    logout(db, token)


@app.post("/v1/auth/change-password", response_model=MessageResponse)
def change_account_password(
    data: PasswordChangeRequest,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    try:
        change_password(db, user, data)
        return MessageResponse(message="Mật khẩu đã được cập nhật")
    except AuthenticationError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except AccountConflictError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error


@app.get("/v1/organization/members", response_model=list[UserResponse])
def get_organization_members(
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
):
    try:
        return list_members(db, user)
    except AuthorizationError as error:
        raise HTTPException(status_code=403, detail=str(error)) from error


@app.post(
    "/v1/organization/members",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_organization_member(
    data: MemberCreate,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
) -> UserResponse:
    try:
        return create_member(db, user, data)
    except AuthorizationError as error:
        raise HTTPException(status_code=403, detail=str(error)) from error
    except AccountConflictError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error
    except EmailDeliveryError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error


@app.patch(
    "/v1/organization/members/{member_id}",
    response_model=UserResponse,
)
def change_organization_member(
    member_id: uuid.UUID,
    data: MemberUpdate,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
) -> UserResponse:
    try:
        return update_member(db, user, member_id, data)
    except AuthenticationError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    except AuthorizationError as error:
        raise HTTPException(status_code=403, detail=str(error)) from error


@app.post(
    "/v1/facilities",
    response_model=FacilityResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_facility(
    data: FacilityCreate,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
) -> FacilityResponse:
    try:
        return create_facility(db, data, user.organization_id)
    except ResourceConflictError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error


@app.get("/v1/facilities", response_model=list[FacilityResponse])
def get_facilities(
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
):
    return list_facilities(db, user.organization_id)


@app.post(
    "/v1/datasets/electricity",
    response_model=DatasetResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_electricity_dataset(
    data: ElectricityDatasetCreate,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
) -> DatasetResponse:
    try:
        return create_electricity_dataset(db, data, user.organization_id)
    except ResourceNotFoundError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error


@app.get(
    "/v1/datasets/{dataset_id}",
    response_model=DatasetDetailResponse,
)
def get_dataset_detail(
    dataset_id: uuid.UUID,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
) -> DatasetDetailResponse:
    try:
        dataset = get_dataset(db, dataset_id, user.organization_id)
        return DatasetDetailResponse(
            **DatasetResponse.model_validate(dataset).model_dump(),
            facility_name=dataset.facility.name,
            meter_name=dataset.meter.name if dataset.meter else None,
        )
    except ResourceNotFoundError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error


@app.get(
    "/v1/datasets/{dataset_id}/measurements",
    response_model=list[MeasurementResponse],
)
def get_dataset_measurements(
    dataset_id: uuid.UUID,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
):
    try:
        return list_measurements(db, dataset_id, user.organization_id)
    except ResourceNotFoundError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error


@app.post(
    "/v1/datasets/{dataset_id}/analyze",
    response_model=TimeSeriesAnalysisResponse,
)
def analyze_saved_dataset(
    dataset_id: uuid.UUID,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
) -> TimeSeriesAnalysisResponse:
    try:
        data = build_time_series_input(db, dataset_id, user.organization_id)
        return analyze_time_series(data)
    except ResourceNotFoundError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    except ResourceConflictError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post(
    "/v1/datasets/{dataset_id}/ai-insight",
    response_model=GeminiDatasetInsightResponse,
)
def generate_saved_dataset_ai_insight(
    dataset_id: uuid.UUID,
    user: User = Depends(ready_user),
    db: Session = Depends(get_db),
) -> GeminiDatasetInsightResponse:
    try:
        data = build_time_series_input(db, dataset_id, user.organization_id)
        analysis = analyze_time_series(data)
        return GeminiInsightService().generate_dataset_insight(
            dataset_id=dataset_id,
            data=data,
            analysis=analysis,
        )
    except ResourceNotFoundError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error
    except ResourceConflictError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    except GeminiNotConfiguredError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error
    except GeminiGenerationError as error:
        raise HTTPException(status_code=502, detail=str(error)) from error


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
    "/analyze/time-series",
    response_model=TimeSeriesAnalysisResponse,
)
def analyze_energy_time_series(
    data: EnergyTimeSeriesInput,
) -> TimeSeriesAnalysisResponse:
    return analyze_time_series(data)


@app.post(
    "/recommendations",
    response_model=RecommendationListResponse,
)
def recommendations(data: EnergyInput) -> RecommendationListResponse:
    return build_recommendations(data)


@app.post("/recommend", response_model=RecommendationResponse)
def recommend(data: EnergyInput) -> RecommendationResponse:
    """Trả giải pháp có thứ hạng cao nhất cho ứng dụng iOS hiện tại."""
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
