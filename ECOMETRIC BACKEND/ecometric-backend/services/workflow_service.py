from sqlalchemy import select
from db_models import ActionTask, Dataset, DatasetInsight, Facility, User
from services.data_store_service import get_dataset, list_measurements, ResourceConflictError, ResourceNotFoundError


def list_datasets(db, organization_id):
    return list(db.scalars(select(Dataset).join(Dataset.facility).where(
        Facility.organization_id == organization_id).order_by(Dataset.created_at.desc(), Dataset.id).limit(100)))


def save_insight(db, dataset_id, response):
    row = db.get(DatasetInsight, dataset_id)
    if row is None:
        row = DatasetInsight(dataset_id=dataset_id, payload={})
        db.add(row)
    row.payload = response.model_dump(mode="json")
    db.commit()
    return response


def get_insight(db, dataset_id, organization_id):
    get_dataset(db, dataset_id, organization_id)
    row = db.get(DatasetInsight, dataset_id)
    if row is None:
        raise ResourceNotFoundError("Bộ dữ liệu chưa có báo cáo AI. Hãy chạy phân tích.")
    return row.payload


def validate_assignee(db, email, organization_id):
    if email and db.scalar(select(User).where(User.organization_id == organization_id,
        User.email == str(email).lower(), User.is_active.is_(True))) is None:
        raise ResourceConflictError("Người phụ trách phải là thành viên đang hoạt động trong công ty")


def create_action(db, dataset_id, organization_id, data):
    get_dataset(db, dataset_id, organization_id)
    validate_assignee(db, data.assignee_email, organization_id)
    existing = db.scalar(select(ActionTask).where(ActionTask.dataset_id == dataset_id, ActionTask.title == data.title))
    if existing:
        return existing
    row = ActionTask(dataset_id=dataset_id, **data.model_dump())
    if row.assignee_email:
        row.assignee_email = str(row.assignee_email).lower()
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


def list_actions(db, dataset_id, organization_id):
    get_dataset(db, dataset_id, organization_id)
    return list(db.scalars(select(ActionTask).where(ActionTask.dataset_id == dataset_id).order_by(ActionTask.created_at)))


def update_action(db, action_id, organization_id, data):
    row = db.get(ActionTask, action_id)
    if row is None:
        raise ResourceNotFoundError("Không tìm thấy công việc")
    get_dataset(db, row.dataset_id, organization_id)
    validate_assignee(db, data.assignee_email, organization_id)
    for key, value in data.model_dump().items():
        setattr(row, key, str(value).lower() if key == "assignee_email" and value else value)
    db.commit()
    db.refresh(row)
    return row


def calculate_impact(db, before_id, organization_id, request):
    before = get_dataset(db, before_id, organization_id)
    after = get_dataset(db, request.after_dataset_id, organization_id)
    if before.facility_id != after.facility_id or before.meter_id != after.meter_id or before.interval != after.interval:
        raise ResourceConflictError("Chọn cùng cơ sở, đồng hồ và chu kỳ để so sánh")
    if after.period_start <= before.period_end:
        raise ResourceConflictError("Kỳ đo sau phải bắt đầu sau kỳ cơ sở, không được chồng lấn")
    left = list_measurements(db, before_id, organization_id)
    right = list_measurements(db, after.id, organization_id)
    if len(left) < 7 or len(right) < 7:
        raise ResourceConflictError("Mỗi giai đoạn cần ít nhất 7 điểm đo")
    production = all(p.production_units and p.production_units > 0 for p in left + right)
    hours = all(p.operating_hours and p.operating_hours > 0 for p in left + right)
    basis = "production" if production else "operating_hours" if hours else "period"
    def exposure(points):
        if basis == "production":
            return sum(float(p.production_units) for p in points)
        if basis == "operating_hours":
            return sum(float(p.operating_hours) for p in points)
        return len(points)
    baseline = sum(float(p.consumption_kwh) for p in left) / exposure(left)
    expected = baseline * exposure(right)
    actual = sum(float(p.consumption_kwh) for p in right)
    saving = expected - actual
    money = saving * request.electricity_price_vnd if request.electricity_price_vnd is not None else None
    daily_money = money / len(right) if money is not None and before.interval == "daily" else None
    return {"basis": basis, "expected_kwh": expected, "actual_kwh": actual,
        "saving_kwh": saving, "reduction_percent": saving / expected * 100 if expected > 0 else 0,
        "saving_vnd": money,
        "avoided_co2_kg": saving * request.emission_factor_kg_per_kwh if request.emission_factor_kg_per_kwh is not None else None,
        "factor_source": request.factor_source,
        "payback_months": request.investment_vnd / (daily_money * 30) if daily_money and daily_money > 0 and request.investment_vnd is not None else None,
        "caveat": "So sánh quan sát, không khẳng định quan hệ nhân quả. Hoàn vốn là ngoại suy 30 ngày từ kỳ đo sau; cần xác minh điều kiện vận hành và mùa vụ."}
