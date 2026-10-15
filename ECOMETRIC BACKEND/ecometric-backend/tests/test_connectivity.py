import os
import unittest
import argparse
from unittest.mock import Mock
from fastapi.testclient import TestClient
from sqlalchemy.exc import SQLAlchemyError

os.environ.setdefault("ECOMETRIC_DB_PASSWORD", "test-only")
from main import app
from database import get_db
from run import parse_arguments, valid_port


class ConnectivityTests(unittest.TestCase):
    def tearDown(self):
        app.dependency_overrides.clear()

    def test_health_checks_database_and_does_not_claim_ai_live(self):
        app.dependency_overrides[get_db] = lambda: Mock()
        with TestClient(app) as client:
            result = client.get("/health")
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.json()["database"], "ok")
        self.assertIn(result.json()["gemini"], {"configured", "not_configured"})

    def test_health_returns_503_when_database_is_unavailable(self):
        db = Mock()
        db.execute.side_effect = SQLAlchemyError("database unavailable")
        app.dependency_overrides[get_db] = lambda: db
        with TestClient(app) as client:
            result = client.get("/health")
        self.assertEqual(result.status_code, 503)
        self.assertEqual(result.json()["status"], "degraded")
        self.assertEqual(result.json()["database"], "unavailable")

    def test_host_port_defaults_and_override_are_explicit(self):
        defaults = parse_arguments([])
        self.assertEqual((defaults.host, defaults.port), ("127.0.0.1", 8000))
        lan = parse_arguments(["--host", "0.0.0.0", "--port", "8001"])
        self.assertEqual((lan.host, lan.port), ("0.0.0.0", 8001))
        for invalid in ["0", "-1", "65536", "abc"]:
            with self.assertRaises(argparse.ArgumentTypeError):
                valid_port(invalid)
