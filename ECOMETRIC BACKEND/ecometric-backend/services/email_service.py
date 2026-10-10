import smtplib
from email.message import EmailMessage

from settings import Settings


class EmailDeliveryError(Exception):
    pass


def send_registration_otp(settings: Settings, recipient: str, code: str) -> None:
    if settings.email_delivery_mode == "console":
        print(f"[EcoMetric local] OTP đăng ký cho {recipient}: {code}")
        return

    message = EmailMessage()
    message["Subject"] = "[EcoMetric] Mã xác minh đăng ký tài khoản doanh nghiệp"
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(
        "Kính gửi Quý khách hàng,\n\n"
        "Hệ thống EcoMetric xin trân trọng thông báo: Chúng tôi đã nhận được "
        "yêu cầu đăng ký tài khoản doanh nghiệp bằng địa chỉ email này.\n\n"
        "Thông tin xác minh:\n\n"
        "• Hệ thống: EcoMetric\n"
        f"• Email đăng ký: {recipient}\n"
        f"• Mã xác minh OTP: {code}\n\n"
        "Lưu ý bảo mật quan trọng:\n\n"
        "1. Mã xác minh chỉ có hiệu lực trong vòng 10 phút kể từ thời điểm "
        "nhận thông báo này.\n"
        "2. Vui lòng không chia sẻ mã xác minh với bất kỳ cá nhân hoặc tổ chức nào.\n"
        "3. Nếu bạn không thực hiện yêu cầu đăng ký này, vui lòng bỏ qua email "
        "và không cung cấp mã xác minh cho người khác.\n\n"
        "Nếu có bất kỳ thắc mắc hoặc cần hỗ trợ thêm trong quá trình đăng ký, "
        "xin vui lòng phản hồi lại email này hoặc liên hệ với Bộ phận Hỗ trợ "
        "Kỹ thuật EcoMetric.\n\n"
        "Trân trọng,\n"
        "Nguyễn Xuân Thành\n"
        "Đội ngũ Quản trị Hệ thống EcoMetric"
    )
    _send_message(settings, message)


def send_member_invitation(
    settings: Settings,
    recipient: str,
    full_name: str,
    company_name: str,
    role: str,
    temporary_password: str,
) -> None:
    if settings.email_delivery_mode == "console":
        print(f"[EcoMetric local] Đã tạo thư mời nhân viên cho {recipient}")
        return

    role_name = "Quản trị viên" if role == "admin" else "Nhân viên"
    message = EmailMessage()
    message["Subject"] = (
        "[EcoMetric] Thông tin cấp tài khoản và phân quyền truy cập hệ thống"
    )
    message["From"] = settings.smtp_from_email
    message["To"] = recipient
    message.set_content(
        "Kính gửi Quý nhân viên,\n\n"
        "Hệ thống EcoMetric xin trân trọng thông báo: Tài khoản của bạn tại "
        f"{company_name} đã được kích hoạt thành công với các thông tin phân "
        "quyền như sau:\n\n"
        "• Hệ thống: EcoMetric\n"
        f"• Vai trò: {role_name}\n"
        f"• Email đăng nhập: {recipient}\n"
        f"• Mật khẩu tạm thời: {temporary_password}\n\n"
        "Lưu ý bảo mật quan trọng:\n\n"
        "1. Mật khẩu tạm thời chỉ có hiệu lực trong vòng 24 giờ kể từ thời "
        "điểm nhận thông báo này.\n"
        "2. Trong lần đăng nhập đầu tiên, bạn bắt buộc phải thiết lập mật khẩu "
        "mới để đảm bảo tính an toàn cho tài khoản.\n"
        "3. Nhằm tuân thủ quy định bảo mật thông tin nội bộ, vui lòng không "
        "chia sẻ hay chuyển tiếp email này dưới bất kỳ hình thức nào.\n\n"
        "Nếu có bất kỳ thắc mắc hoặc cần hỗ trợ thêm trong quá trình truy cập "
        "hệ thống, xin vui lòng phản hồi lại email này hoặc liên hệ với Bộ phận "
        "Hỗ trợ Kỹ thuật EcoMetric.\n\n"
        "Trân trọng,\n"
        "Nguyễn Xuân Thành\n"
        "Đội ngũ Quản trị Hệ thống EcoMetric"
    )
    _send_message(settings, message)


def _validate_smtp_settings(settings: Settings) -> None:
    required = {
        "ECOMETRIC_SMTP_HOST": settings.smtp_host,
        "ECOMETRIC_SMTP_USERNAME": settings.smtp_username,
        "ECOMETRIC_SMTP_PASSWORD": settings.smtp_password,
        "ECOMETRIC_SMTP_FROM_EMAIL": settings.smtp_from_email,
    }
    missing = [name for name, value in required.items() if not value]
    if missing:
        raise EmailDeliveryError(
            "Thiếu cấu hình gửi email: " + ", ".join(missing)
        )


def _send_message(settings: Settings, message: EmailMessage) -> None:
    _validate_smtp_settings(settings)

    try:
        if settings.smtp_use_ssl:
            with smtplib.SMTP_SSL(settings.smtp_host, settings.smtp_port) as smtp:
                smtp.login(settings.smtp_username, settings.smtp_password)
                smtp.send_message(message)
        else:
            with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as smtp:
                smtp.ehlo()
                if settings.smtp_use_tls:
                    smtp.starttls()
                    smtp.ehlo()
                smtp.login(settings.smtp_username, settings.smtp_password)
                smtp.send_message(message)
    except (OSError, smtplib.SMTPException) as error:
        raise EmailDeliveryError(
            "Không thể gửi email. Vui lòng kiểm tra cấu hình SMTP"
        ) from error
