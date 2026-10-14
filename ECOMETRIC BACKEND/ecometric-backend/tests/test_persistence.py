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
from services.workflow_service import calculate_impact, create_action, list_actions, list_datasets, update_action, get_insight, save_insight
from workflow_schemas import ImpactRequest, ActionCreate, ActionUpdate


class PersistenceTests(unittest.TestCase):
    def _workflow_dataset(self, session, organization, start, consumption, production):
        facilities = list_facilities(session, organization.id)
        facility = facilities[0] if facilities else create_facility(session, FacilityCreate(name="Xưởng đo lại"), organization.id)
        return create_electricity_dataset(session, ElectricityDatasetCreate(facility_id=facility.id,
            points=[EnergyTimeSeriesPoint(timestamp=start + timedelta(days=i), consumption_kwh=consumption,
                production_units=production) for i in range(7)]), organization.id)

    def test_impact_normalizes_production_and_calculates_verified_inputs(self):
        with self.session_factory() as session:
            organization = self._make_organization(session)
            before = self._workflow_dataset(session, organization, datetime(2026, 10, 1), 100, 10)
            after = self._workflow_dataset(session, organization, datetime(2026, 10, 8), 160, 20)
            result = calculate_impact(session, before.id, organization.id, ImpactRequest(after_dataset_id=after.id,
                electricity_price_vnd=2000, investment_vnd=1920000, emission_factor_kg_per_kwh=0.5, factor_source="Tài liệu kiểm thử 2026"))
            self.assertEqual(result["basis"], "production")
            self.assertEqual(result["saving_kwh"], 280)
            self.assertEqual(result["saving_vnd"], 560000)
            self.assertEqual(result["avoided_co2_kg"], 140)
            self.assertAlmostEqual(result["payback_months"], 0.8)

    def test_impact_rejects_overlap_and_unreferenced_factor(self):
        with self.assertRaises(ValidationError):
            ImpactRequest(after_dataset_id=uuid.uuid4(), emission_factor_kg_per_kwh=0.5)
        with self.session_factory() as session:
            organization = self._make_organization(session)
            before = self._workflow_dataset(session, organization, datetime(2026, 10, 1), 100, 10)
            after = self._workflow_dataset(session, organization, datetime(2026, 10, 4), 80, 10)
            with self.assertRaises(ResourceConflictError):
                calculate_impact(session, before.id, organization.id, ImpactRequest(after_dataset_id=after.id))

    def test_actions_and_history_are_tenant_isolated(self):
        with self.session_factory() as session:
            organization = self._make_organization(session)
            other = self._make_organization(session)
            before = self._workflow_dataset(session, organization, datetime(2026, 10, 1), 100, 10)
            task = create_action(session, before.id, organization.id, ActionCreate(title="Kiểm tra máy", verification_metric="kWh/sản phẩm"))
            self.assertEqual(len(list_datasets(session, organization.id)), 1)
            self.assertEqual(len(list_datasets(session, other.id)), 0)
            self.assertEqual(len(list_actions(session, before.id, organization.id)), 1)
            with self.assertRaises(ResourceNotFoundError):
                list_actions(session, before.id, other.id)
            with self.assertRaises(ResourceNotFoundError):
                update_action(session, task.id, other.id, ActionUpdate(status="completed"))
            with self.assertRaises(ResourceConflictError):
                update_action(session, task.id, organization.id, ActionUpdate(status="planned", assignee_email="outside@example.com"))

    def test_insight_is_saved_and_requires_own_tenant(self):
        from types import SimpleNamespace
        with self.session_factory() as session:
            organization = self._make_organization(session)
            other = self._make_organization(session)
            before = self._workflow_dataset(session, organization, datetime(2026, 10, 1), 100, 10)
            response = SimpleNamespace(model_dump=lambda **_: {"headline": "Báo cáo đã lưu"})
            save_insight(session, before.id, response)
            self.assertEqual(get_insight(session, before.id, organization.id)["headline"], "Báo cáo đã lưu")
            with self.assertRaises(ResourceNotFoundError):
                get_insight(session, before.id, other.id)
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
                    operational_context="Máy nén khí chạy trong giờ nghỉ",
                    desired_outcome="Giảm điện nhưng giữ nguyên sản lượng",
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
            self.assertEqual(
                dataset.operational_context,
                "Máy nén khí chạy trong giờ nghỉ",
            )
            self.assertEqual(
                dataset.desired_outcome,
                "Giảm điện nhưng giữ nguyên sản lượng",
            )
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
