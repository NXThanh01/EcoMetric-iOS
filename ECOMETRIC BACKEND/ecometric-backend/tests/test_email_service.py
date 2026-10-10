import os
import unittest
from unittest.mock import patch

os.environ.setdefault("ECOMETRIC_DB_PASSWORD", "test-only")

from services.email_service import (  # noqa: E402
    send_member_invitation,
    send_registration_otp,
)
from settings import Settings  # noqa: E402


class EmailTemplateTests(unittest.TestCase):
    def setUp(self):
        self.settings = Settings(
            db_password="test-only",
            email_delivery_mode="smtp",
            smtp_host="smtp.example.com",
            smtp_username="sender@example.com",
            smtp_password="test-only",
            smtp_from_email="sender@example.com",
        )

    @patch("services.email_service._send_message")
    def test_registration_otp_uses_formal_template(self, send_message):
        send_registration_otp(
            self.settings,
            "owner@example.com",
            "123456",
        )
        message = send_message.call_args.args[1]
        content = message.get_content()

        self.assertEqual(
            message["Subject"],
            "[EcoMetric] Mã xác minh đăng ký tài khoản doanh nghiệp",
        )
        self.assertIn("Kính gửi Quý khách hàng", content)
        self.assertIn("• Mã xác minh OTP: 123456", content)
        self.assertIn("Nguyễn Xuân Thành", content)

    @patch("services.email_service._send_message")
    def test_member_invitation_uses_formal_template(self, send_message):
        send_member_invitation(
            self.settings,
            "employee@example.com",
            "Nhân viên A",
            "Công ty Xanh",
            "member",
            "MatKhauTam123",
        )
        message = send_message.call_args.args[1]
        content = message.get_content()

        self.assertEqual(
            message["Subject"],
            "[EcoMetric] Thông tin cấp tài khoản và phân quyền truy cập hệ thống",
        )
        self.assertIn("Kính gửi Quý nhân viên", content)
        self.assertIn("• Vai trò: Nhân viên", content)
        self.assertIn("Mật khẩu tạm thời: MatKhauTam123", content)
        self.assertIn("Nguyễn Xuân Thành", content)


if __name__ == "__main__":
    unittest.main()
