"""Kiểm tra nhanh đăng ký, đăng nhập và phân quyền trên API đang chạy."""

import json
import sys
import uuid
from pathlib import Path
from urllib import request

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from database import SessionLocal
from db_models import Organization, RegistrationOTP


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
    with request.urlopen(req, timeout=20) as response:
        data = response.read()
        return json.loads(data) if data else None


def main():
    suffix = uuid.uuid4().hex[:10]
    owner_email = f"owner-{suffix}@example.com"
    employee_email = f"employee-{suffix}@example.com"
    organization_id = None

    try:
        otp_response = call(
            "v1/auth/registration-otp",
            method="POST",
            payload={"email": owner_email},
        )
        otp = otp_response.get("development_code")
        if not otp:
            raise RuntimeError(
                "Smoke test cần ECOMETRIC_EMAIL_DELIVERY_MODE=console"
            )
        auth = call(
            "v1/auth/register-company",
            method="POST",
            payload={
                "company_name": f"Công ty kiểm thử {suffix}",
                "owner_name": "Chủ sở hữu kiểm thử",
                "email": owner_email,
                "password": "MatKhau123",
                "otp": otp,
            },
        )
        token = auth["access_token"]
        organization_id = uuid.UUID(auth["organization"]["id"])
        assert auth["user"]["role"] == "owner"

        member = call(
            "v1/organization/members",
            method="POST",
            token=token,
            payload={
                "email": employee_email,
                "full_name": "Nhân viên kiểm thử",
                "password": "NhanVien123",
                "role": "member",
            },
        )
        promoted = call(
            f"v1/organization/members/{member['id']}",
            method="PATCH",
            token=token,
            payload={"role": "admin"},
        )
        assert promoted["role"] == "admin"

        context = call("v1/auth/me", token=token)
        members = call("v1/organization/members", token=token)
        assert context["organization"]["id"] == str(organization_id)
        assert len(members) == 2
        print("Phân quyền API đã hoạt động: owner → admin → member.")
    finally:
        if organization_id is not None:
            with SessionLocal() as session:
                organization = session.get(Organization, organization_id)
                if organization is not None:
                    session.delete(organization)
                    session.commit()
        else:
            with SessionLocal() as session:
                session.query(RegistrationOTP).filter(
                    RegistrationOTP.email == owner_email
                ).delete()
                session.commit()


if __name__ == "__main__":
    main()
