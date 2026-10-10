"""Kiểm tra thư mời, đăng nhập tạm và đổi mật khẩu qua API local."""

import json
import sys
import uuid
from pathlib import Path
from urllib import request

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from auth_schemas import OrganizationBootstrapRequest
from database import SessionLocal
from db_models import Organization
from services.auth_service import bootstrap_organization, request_registration_otp
from settings import Settings, get_settings


BASE_URL = "http://127.0.0.1:8000"


def call(path, method="GET", payload=None, token=None):
    body = json.dumps(payload).encode("utf-8") if payload is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = request.Request(
        f"{BASE_URL}/{path}",
        data=body,
        headers=headers,
        method=method,
    )
    with request.urlopen(req, timeout=30) as response:
        data = response.read()
        return json.loads(data) if data else None


def main():
    settings = get_settings()
    suffix = uuid.uuid4().hex[:8]
    local, domain = settings.smtp_from_email.rsplit("@", 1)
    employee_email = f"{local}+member-{suffix}@{domain}"
    owner_email = f"owner-{suffix}@example.com"
    temporary_password = f"Tam{suffix}Aa1"
    new_password = f"Moi{suffix}Bb2"
    organization_id = None

    test_settings = Settings(
        db_password=settings.db_password,
        email_delivery_mode="console",
        otp_secret=settings.effective_otp_secret,
    )

    try:
        with SessionLocal() as session:
            otp = request_registration_otp(
                session,
                owner_email,
                settings=test_settings,
                deliver=lambda *_args: None,
            )
            auth = bootstrap_organization(
                session,
                OrganizationBootstrapRequest(
                    company_name="EcoMetric Invitation Test",
                    owner_name="Chủ tài khoản kiểm thử",
                    email=owner_email,
                    password="OwnerTest123",
                    otp=otp.development_code,
                ),
                settings=test_settings,
            )
            token = auth.access_token
            organization_id = auth.organization.id

        member = call(
            "v1/organization/members",
            method="POST",
            token=token,
            payload={
                "email": employee_email,
                "full_name": "Nhân viên kiểm thử",
                "password": temporary_password,
                "role": "member",
            },
        )
        assert member["must_change_password"] is True

        employee_auth = call(
            "v1/auth/login",
            method="POST",
            payload={"email": employee_email, "password": temporary_password},
        )
        assert employee_auth["user"]["must_change_password"] is True

        call(
            "v1/auth/change-password",
            method="POST",
            token=employee_auth["access_token"],
            payload={
                "current_password": temporary_password,
                "new_password": new_password,
            },
        )
        changed_auth = call(
            "v1/auth/login",
            method="POST",
            payload={"email": employee_email, "password": new_password},
        )
        assert changed_auth["user"]["must_change_password"] is False
        print("Thư mời và luồng đổi mật khẩu tạm đã hoạt động.")
    finally:
        if organization_id is not None:
            with SessionLocal() as session:
                organization = session.get(Organization, organization_id)
                if organization is not None:
                    session.delete(organization)
                    session.commit()


if __name__ == "__main__":
    main()
