"""Kiểm tra hợp đồng HTTP, phân quyền và cách ly công việc/báo cáo."""
import os
import unittest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

os.environ.setdefault("ECOMETRIC_DB_PASSWORD", "test-only")
from database import Base, get_db
from db_models import Organization, User
from main import app, ready_user
from persistence_schemas import FacilityCreate, ElectricityDatasetCreate
from schemas import EnergyTimeSeriesPoint
from services.data_store_service import create_facility, create_electricity_dataset


class WorkflowAPITests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        Base.metadata.create_all(self.engine)
        self.db = Session(self.engine)
        company = Organization(name="Kiểm thử workflow")
        self.db.add(company)
        self.db.flush()
        self.user = User(organization_id=company.id, email="owner@example.com", full_name="Quản lý", password_hash="test", role="owner")
        self.db.add(self.user)
        self.db.commit()
        facility = create_facility(self.db, FacilityCreate(name="Cơ sở thử"), company.id)
        self.datasets = []
        for offset, value in [(0, 100), (7, 80)]:
            self.datasets.append(create_electricity_dataset(self.db, ElectricityDatasetCreate(facility_id=facility.id,
                points=[EnergyTimeSeriesPoint(timestamp=datetime(2026, 10, 1) + timedelta(days=i + offset),
                    consumption_kwh=value, production_units=10) for i in range(7)]), company.id))
        app.dependency_overrides[get_db] = lambda: self.db
        app.dependency_overrides[ready_user] = lambda: self.user
        self.client = TestClient(app)

    def tearDown(self):
        self.client.close()
        app.dependency_overrides.clear()
        self.db.close()
        self.engine.dispose()

    def test_history_actions_impact_contract_and_role(self):
        before, after = self.datasets
        self.assertEqual(len(self.client.get("/v1/datasets").json()), 2)
        response = self.client.post(f"/v1/datasets/{before.id}/actions", json={"title": "Kiểm tra máy nén", "verification_metric": "kWh/sản phẩm"})
        self.assertEqual(response.status_code, 201)
        task_id = response.json()["id"]
        self.user.role = "member"
        self.assertEqual(self.client.patch(f"/v1/actions/{task_id}", json={"status": "completed"}).status_code, 403)
        self.user.role = "owner"
        self.assertEqual(self.client.patch(f"/v1/actions/{task_id}", json={"status": "completed", "notes": "Đã kiểm tra"}).json()["status"], "completed")
        impact = self.client.post(f"/v1/datasets/{before.id}/impact", json={"after_dataset_id": str(after.id), "electricity_price_vnd": 2000})
        self.assertEqual(impact.status_code, 200)
        self.assertAlmostEqual(impact.json()["reduction_percent"], 20)
        self.assertIsNone(impact.json()["avoided_co2_kg"])
        self.assertEqual(self.client.get(f"/v1/datasets/{before.id}/ai-insight").status_code, 404)

    def test_other_company_cannot_read_or_mutate(self):
        before, _ = self.datasets
        task = self.client.post(f"/v1/datasets/{before.id}/actions", json={"title": "Kiểm tra", "verification_metric": "kWh"}).json()
        other = Organization(name="Công ty khác")
        self.db.add(other)
        self.db.flush()
        self.user.organization_id = other.id
        self.db.commit()
        self.assertEqual(self.client.get("/v1/datasets").json(), [])
        self.assertEqual(self.client.get(f"/v1/datasets/{before.id}/actions").status_code, 404)
        self.assertEqual(self.client.get(f"/v1/datasets/{before.id}/ai-insight").status_code, 404)
        self.assertEqual(self.client.patch(f"/v1/actions/{task['id']}", json={"status": "completed"}).status_code, 404)
