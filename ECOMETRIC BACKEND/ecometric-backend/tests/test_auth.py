import os
import unittest

from fastapi import HTTPException
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

os.environ.setdefault("ECOMETRIC_DB_PASSWORD", "test-only")

from auth_schemas import (  # noqa: E402
    LoginRequest,
    MemberCreate,
    MemberUpdate,
    OrganizationBootstrapRequest,
    PasswordChangeRequest,
)
from database import Base  # noqa: E402
from main import ready_user  # noqa: E402
from services.auth_service import (  # noqa: E402
    AuthorizationError,
    OTPRateLimitError,
    OTPVerificationError,
    bootstrap_organization,
    change_password,
    create_member,
    get_user_by_token,
    login,
    request_registration_otp,
    update_member,
)
from settings import Settings  # noqa: E402


class AuthenticationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.settings = Settings(
            db_password="test-only",
            email_delivery_mode="console",
        )
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

    def _create_owner(self, session):
        delivery = request_registration_otp(
            session,
            "owner@example.com",
            settings=self.settings,
            deliver=lambda _settings, _email, _code: None,
        )
        return bootstrap_organization(
            session,
            OrganizationBootstrapRequest(
                company_name="Công ty Xanh",
                owner_name="Nguyễn Chủ",
                email="owner@example.com",
                password="MatKhau123",
                otp=delivery.development_code,
            ),
            settings=self.settings,
        )

    def test_registration_requires_correct_otp(self):
        with self.session_factory() as session:
            delivery = request_registration_otp(
                session,
                "owner@example.com",
                settings=self.settings,
                deliver=lambda _settings, _email, _code: None,
            )
            self.assertEqual(len(delivery.development_code), 6)
            wrong_code = (
                "000000" if delivery.development_code != "000000" else "111111"
            )

            with self.assertRaises(OTPVerificationError):
                bootstrap_organization(
                    session,
                    OrganizationBootstrapRequest(
                        company_name="Công ty Xanh",
                        owner_name="Nguyễn Chủ",
                        email="owner@example.com",
                        password="MatKhau123",
                        otp=wrong_code,
                    ),
                    settings=self.settings,
                )

    def test_registration_otp_has_resend_cooldown(self):
        with self.session_factory() as session:
            request_registration_otp(
                session,
                "owner@example.com",
                settings=self.settings,
                deliver=lambda _settings, _email, _code: None,
            )
            with self.assertRaises(OTPRateLimitError):
                request_registration_otp(
                    session,
                    "owner@example.com",
                    settings=self.settings,
                    deliver=lambda _settings, _email, _code: None,
                )

    def test_owner_registers_and_logs_in(self):
        with self.session_factory() as session:
            auth = self._create_owner(session)
            current = get_user_by_token(session, auth.access_token)
            logged_in = login(
                session,
                LoginRequest(
                    email="OWNER@example.com",
                    password="MatKhau123",
                ),
            )

            self.assertEqual(current.role, "owner")
            self.assertEqual(current.organization.name, "Công ty Xanh")
            self.assertTrue(logged_in.access_token)

    def test_owner_can_promote_employee_to_admin(self):
        with self.session_factory() as session:
            auth = self._create_owner(session)
            owner = get_user_by_token(session, auth.access_token)
            employee = create_member(
                session,
                owner,
                MemberCreate(
                    email="employee@example.com",
                    full_name="Nhân viên A",
                    password="NhanVien123",
                    role="member",
                ),
                deliver=lambda *_args: None,
            )
            updated = update_member(
                session,
                owner,
                employee.id,
                MemberUpdate(role="admin"),
            )

            self.assertEqual(updated.role, "admin")
            self.assertTrue(updated.must_change_password)

    def test_admin_cannot_promote_another_admin(self):
        with self.session_factory() as session:
            auth = self._create_owner(session)
            owner = get_user_by_token(session, auth.access_token)
            admin = create_member(
                session,
                owner,
                MemberCreate(
                    email="admin@example.com",
                    full_name="Quản trị viên",
                    password="Admin1234",
                    role="admin",
                ),
                deliver=lambda *_args: None,
            )
            employee = create_member(
                session,
                owner,
                MemberCreate(
                    email="employee@example.com",
                    full_name="Nhân viên A",
                    password="NhanVien123",
                    role="member",
                ),
                deliver=lambda *_args: None,
            )

            with self.assertRaises(AuthorizationError):
                update_member(
                    session,
                    admin,
                    employee.id,
                    MemberUpdate(role="admin"),
                )

    def test_employee_must_change_temporary_password(self):
        with self.session_factory() as session:
            auth = self._create_owner(session)
            owner = get_user_by_token(session, auth.access_token)
            employee = create_member(
                session,
                owner,
                MemberCreate(
                    email="employee@example.com",
                    full_name="Nhân viên A",
                    password="NhanVien123",
                    role="member",
                ),
                deliver=lambda *_args: None,
            )

            change_password(
                session,
                employee,
                PasswordChangeRequest(
                    current_password="NhanVien123",
                    new_password="MatKhauMoi123",
                ),
            )
            logged_in = login(
                session,
                LoginRequest(
                    email="employee@example.com",
                    password="MatKhauMoi123",
                ),
            )

            self.assertFalse(logged_in.user.must_change_password)

    def test_employee_cannot_use_business_api_before_password_change(self):
        with self.session_factory() as session:
            auth = self._create_owner(session)
            owner = get_user_by_token(session, auth.access_token)
            employee = create_member(
                session,
                owner,
                MemberCreate(
                    email="employee@example.com",
                    full_name="Nhân viên A",
                    password="NhanVien123",
                    role="member",
                ),
                deliver=lambda *_args: None,
            )

            with self.assertRaises(HTTPException) as context:
                ready_user(employee)
            self.assertEqual(context.exception.status_code, 403)


if __name__ == "__main__":
    unittest.main()
