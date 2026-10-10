import os
import unittest
import uuid
from datetime import datetime, timedelta

from pydantic import ValidationError
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Cung cấp cấu hình tối thiểu trước khi nạp tầng database. Các test bên dưới
# chỉ dùng SQLite trong bộ nhớ và không kết nối PostgreSQL thật.
os.environ.setdefault("ECOMETRIC_DB_PASSWORD", "test-only")

from database import Base  # noqa: E402
from db_models import Organization  # noqa: E402
from persistence_schemas import (  # noqa: E402
    ElectricityDatasetCreate,
    FacilityCreate,
)
from schemas import EnergyTimeSeriesPoint  # noqa: E402
from services.data_store_service import (  # noqa: E402
    ResourceConflictError,
    ResourceNotFoundError,
    build_time_series_input,
    create_electricity_dataset,
    create_facility,
    get_dataset,
    list_facilities,
    list_measurements,
)
from services.time_series_service import analyze_time_series  # noqa: E402


class PersistenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine(
            "sqlite+pysqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )

        @event.listens_for(cls.engine, "connect")
        def enable_foreign_keys(dbapi_connection, _):
            dbapi_connection.execute("PRAGMA foreign_keys=ON")

        Base.metadata.create_all(cls.engine)
        cls.session_factory = sessionmaker(
            bind=cls.engine,
            autoflush=False,
            expire_on_commit=False,
        )

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(cls.engine)
        cls.engine.dispose()

    def setUp(self):
        with self.session_factory() as session:
            for table in reversed(Base.metadata.sorted_tables):
                session.execute(table.delete())
            session.commit()

    def _make_points(self):
        start = datetime(2026, 10, 1)
        values = [100, 101, 99, 100, 102, 98, 160]
        return [
            EnergyTimeSeriesPoint(
                timestamp=start + timedelta(days=index),
                consumption_kwh=value,
                production_units=10,
                operating_hours=8,
            )
            for index, value in enumerate(values)
        ]

    def _make_organization(self, session):
        organization = Organization(
            name="Công ty kiểm thử",
            plan_code="business",
            subscription_status="active",
            seat_limit=10,
        )
        session.add(organization)
        session.flush()
        return organization

    def test_stores_reads_and_analyzes_real_measurements(self):
        with self.session_factory() as session:
            organization = self._make_organization(session)
            facility = create_facility(
                session,
                FacilityCreate(name="Xưởng kiểm thử"),
                organization.id,
            )
            dataset = create_electricity_dataset(
                session,
                ElectricityDatasetCreate(
                    facility_id=facility.id,
                    meter_name="Đồng hồ tổng",
                    source_type="manual",
                    interval="daily",
                    points=self._make_points(),
                ),
                organization.id,
            )

            measurements = list_measurements(
                session,
                dataset.id,
                organization.id,
            )
            analysis_input = build_time_series_input(
                session,
                dataset.id,
                organization.id,
            )
            result = analyze_time_series(analysis_input)

            self.assertEqual(dataset.record_count, 7)
            self.assertEqual(len(measurements), 7)
            self.assertEqual(len(result.anomalies), 1)

    def test_rejects_duplicate_timestamps(self):
        point = self._make_points()[0]

        with self.assertRaises(ValidationError):
            ElectricityDatasetCreate(
                facility_id=uuid.uuid4(),
                points=[point, point],
            )

    def test_rejects_unknown_facility(self):
        with self.session_factory() as session:
            organization = self._make_organization(session)
            with self.assertRaises(ResourceNotFoundError):
                create_electricity_dataset(
                    session,
                    ElectricityDatasetCreate(
                        facility_id=uuid.uuid4(),
                        points=self._make_points(),
                    ),
                    organization.id,
                )

    def test_requires_seven_saved_points_for_analysis(self):
        with self.session_factory() as session:
            organization = self._make_organization(session)
            facility = create_facility(
                session,
                FacilityCreate(name="Xưởng ít dữ liệu"),
                organization.id,
            )
            dataset = create_electricity_dataset(
                session,
                ElectricityDatasetCreate(
                    facility_id=facility.id,
                    points=self._make_points()[:3],
                ),
                organization.id,
            )

            with self.assertRaises(ResourceConflictError):
                build_time_series_input(
                    session,
                    dataset.id,
                    organization.id,
                )

    def test_isolates_facilities_and_datasets_between_organizations(self):
        with self.session_factory() as session:
            first = self._make_organization(session)
            second = Organization(
                name="Công ty khác",
                plan_code="business",
                subscription_status="active",
                seat_limit=10,
            )
            session.add(second)
            session.flush()

            facility = create_facility(
                session,
                FacilityCreate(name="Xưởng riêng"),
                first.id,
            )
            dataset = create_electricity_dataset(
                session,
                ElectricityDatasetCreate(
                    facility_id=facility.id,
                    points=self._make_points(),
                ),
                first.id,
            )

            self.assertEqual(len(list_facilities(session, first.id)), 1)
            self.assertEqual(list_facilities(session, second.id), [])
            with self.assertRaises(ResourceNotFoundError):
                get_dataset(session, dataset.id, second.id)


if __name__ == "__main__":
    unittest.main()
