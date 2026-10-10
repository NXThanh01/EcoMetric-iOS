import uuid
from decimal import Decimal
from typing import List

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from db_models import Dataset, Facility, Measurement, Meter
from persistence_schemas import ElectricityDatasetCreate, FacilityCreate
from schemas import EnergyTimeSeriesInput, EnergyTimeSeriesPoint


class ResourceNotFoundError(Exception):
    pass


class ResourceConflictError(Exception):
    pass


def create_facility(
    session: Session,
    data: FacilityCreate,
    organization_id: uuid.UUID,
) -> Facility:
    existing = session.scalar(
        select(Facility).where(
            Facility.organization_id == organization_id,
            Facility.name == data.name,
        )
    )
    if existing is not None:
        raise ResourceConflictError("Tên cơ sở đã tồn tại")

    facility = Facility(
        organization_id=organization_id,
        name=data.name,
        timezone=data.timezone,
    )
    session.add(facility)
    session.commit()
    session.refresh(facility)
    return facility


def list_facilities(
    session: Session,
    organization_id: uuid.UUID,
) -> List[Facility]:
    return list(
        session.scalars(
            select(Facility)
            .where(Facility.organization_id == organization_id)
            .order_by(Facility.name)
        )
    )


def _get_or_create_meter(
    session: Session,
    facility_id: uuid.UUID,
    meter_name: str,
) -> Meter:
    meter = session.scalar(
        select(Meter).where(
            Meter.facility_id == facility_id,
            Meter.name == meter_name,
        )
    )
    if meter is not None:
        return meter

    meter = Meter(
        facility_id=facility_id,
        name=meter_name,
        data_type="electricity",
        unit="kWh",
    )
    session.add(meter)
    session.flush()
    return meter


def create_electricity_dataset(
    session: Session,
    data: ElectricityDatasetCreate,
    organization_id: uuid.UUID,
) -> Dataset:
    facility = session.get(Facility, data.facility_id)
    if facility is None or facility.organization_id != organization_id:
        raise ResourceNotFoundError("Không tìm thấy cơ sở")

    sorted_points = sorted(data.points, key=lambda point: point.timestamp)

    try:
        meter = _get_or_create_meter(
            session,
            data.facility_id,
            data.meter_name,
        )
        dataset = Dataset(
            facility_id=data.facility_id,
            meter_id=meter.id,
            source_type=data.source_type,
            interval=data.interval,
            status="ready",
            operational_context=data.operational_context,
            desired_outcome=data.desired_outcome,
            record_count=len(sorted_points),
            period_start=sorted_points[0].timestamp,
            period_end=sorted_points[-1].timestamp,
        )
        session.add(dataset)
        session.flush()

        session.add_all(
            [
                Measurement(
                    dataset_id=dataset.id,
                    timestamp=point.timestamp,
                    consumption_kwh=Decimal(str(point.consumption_kwh)),
                    production_units=(
                        Decimal(str(point.production_units))
                        if point.production_units is not None
                        else None
                    ),
                    operating_hours=(
                        Decimal(str(point.operating_hours))
                        if point.operating_hours is not None
                        else None
                    ),
                )
                for point in sorted_points
            ]
        )
        session.commit()
        session.refresh(dataset)
        return dataset
    except Exception:
        session.rollback()
        raise


def get_dataset(
    session: Session,
    dataset_id: uuid.UUID,
    organization_id: uuid.UUID,
) -> Dataset:
    dataset = session.scalar(
        select(Dataset)
        .options(selectinload(Dataset.facility), selectinload(Dataset.meter))
        .where(
            Dataset.id == dataset_id,
            Facility.organization_id == organization_id,
        )
        .join(Dataset.facility)
    )
    if dataset is None:
        raise ResourceNotFoundError("Không tìm thấy bộ dữ liệu")
    return dataset


def list_measurements(
    session: Session,
    dataset_id: uuid.UUID,
    organization_id: uuid.UUID,
) -> List[Measurement]:
    get_dataset(session, dataset_id, organization_id)

    return list(
        session.scalars(
            select(Measurement)
            .where(Measurement.dataset_id == dataset_id)
            .order_by(Measurement.timestamp)
        )
    )


def build_time_series_input(
    session: Session,
    dataset_id: uuid.UUID,
    organization_id: uuid.UUID,
) -> EnergyTimeSeriesInput:
    dataset = get_dataset(session, dataset_id, organization_id)
    measurements = list_measurements(session, dataset_id, organization_id)
    if len(measurements) < 7:
        raise ResourceConflictError(
            "Cần ít nhất 7 điểm đo trước khi chạy phân tích AI"
        )

    return EnergyTimeSeriesInput(
        facility_name=dataset.facility.name,
        interval=dataset.interval,
        points=[
            EnergyTimeSeriesPoint(
                timestamp=item.timestamp,
                consumption_kwh=float(item.consumption_kwh),
                production_units=(
                    float(item.production_units)
                    if item.production_units is not None
                    else None
                ),
                operating_hours=(
                    float(item.operating_hours)
                    if item.operating_hours is not None
                    else None
                ),
            )
            for item in measurements
        ],
    )
