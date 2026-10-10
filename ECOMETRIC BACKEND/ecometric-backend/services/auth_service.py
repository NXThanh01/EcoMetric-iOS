import base64
import hashlib
import hmac
import secrets
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Callable, List, Optional

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from auth_schemas import (
    AuthResponse,
    LoginRequest,
    MemberCreate,
    MemberUpdate,
    OrganizationBootstrapRequest,
    PasswordChangeRequest,
)
from db_models import AuthSession, Organization, RegistrationOTP, User
from services.email_service import send_member_invitation, send_registration_otp
from settings import Settings, get_settings


class AuthenticationError(Exception):
    pass


class AuthorizationError(Exception):
    pass


class AccountConflictError(Exception):
    pass


class OTPVerificationError(Exception):
    pass


class OTPRateLimitError(Exception):
    pass


PASSWORD_ITERATIONS = 600_000
SESSION_DURATION_DAYS = 30
TEMPORARY_PASSWORD_HOURS = 24
OTP_TTL_MINUTES = 10
OTP_RESEND_SECONDS = 60
OTP_MAX_ATTEMPTS = 5


@dataclass(frozen=True)
class OTPDeliveryResult:
    expires_in_seconds: int
    resend_after_seconds: int
    development_code: Optional[str]


def _normalized_email(email: str) -> str:
    return email.strip().lower()


def _otp_hash(email: str, code: str, secret: str) -> str:
    payload = f"{_normalized_email(email)}:{code}".encode("utf-8")
    return hmac.new(secret.encode("utf-8"), payload, hashlib.sha256).hexdigest()


def request_registration_otp(
    session: Session,
    email: str,
    settings: Optional[Settings] = None,
    deliver: Optional[Callable[[Settings, str, str], None]] = None,
) -> OTPDeliveryResult:
    settings = settings or get_settings()
    normalized_email = _normalized_email(email)
    if session.scalar(select(User).where(User.email == normalized_email)) is not None:
        raise AccountConflictError("Email này đã được sử dụng")

    now = datetime.now(timezone.utc)
    record = session.scalar(
        select(RegistrationOTP).where(RegistrationOTP.email == normalized_email)
    )
    if record is not None:
        resend_at = record.resend_available_at
        if resend_at.tzinfo is None:
            resend_at = resend_at.replace(tzinfo=timezone.utc)
        if resend_at > now:
            remaining = max(1, int((resend_at - now).total_seconds()))
            raise OTPRateLimitError(
                f"Vui lòng chờ {remaining} giây trước khi gửi lại mã"
            )

    code = f"{secrets.randbelow(1_000_000):06d}"
    if record is None:
        record = RegistrationOTP(email=normalized_email)
        session.add(record)
    record.code_hash = _otp_hash(
        normalized_email,
        code,
        settings.effective_otp_secret,
    )
    record.attempts = 0
    record.expires_at = now + timedelta(minutes=OTP_TTL_MINUTES)
    record.resend_available_at = now + timedelta(seconds=OTP_RESEND_SECONDS)
    record.consumed_at = None

    delivery = deliver or send_registration_otp
    try:
        delivery(settings, normalized_email, code)
        session.commit()
    except Exception:
        session.rollback()
        raise

    return OTPDeliveryResult(
        expires_in_seconds=OTP_TTL_MINUTES * 60,
        resend_after_seconds=OTP_RESEND_SECONDS,
        development_code=(
            code if settings.email_delivery_mode == "console" else None
        ),
    )


def _consume_registration_otp(
    session: Session,
    email: str,
    code: str,
    settings: Settings,
) -> None:
    normalized_email = _normalized_email(email)
    record = session.scalar(
        select(RegistrationOTP).where(RegistrationOTP.email == normalized_email)
    )
    now = datetime.now(timezone.utc)
    if record is None or record.consumed_at is not None:
        raise OTPVerificationError("Mã xác minh không hợp lệ")

    expires_at = record.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at <= now:
        raise OTPVerificationError("Mã xác minh đã hết hạn")
    if record.attempts >= OTP_MAX_ATTEMPTS:
        raise OTPVerificationError("Mã đã bị khóa do nhập sai quá nhiều lần")

    expected = _otp_hash(normalized_email, code, settings.effective_otp_secret)
    if not hmac.compare_digest(record.code_hash, expected):
        record.attempts += 1
        session.commit()
        remaining = OTP_MAX_ATTEMPTS - record.attempts
        raise OTPVerificationError(
            f"Mã xác minh không đúng. Còn {remaining} lần thử"
        )
    record.consumed_at = now


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        PASSWORD_ITERATIONS,
    )
    return "$".join(
        [
            "pbkdf2_sha256",
            str(PASSWORD_ITERATIONS),
            base64.urlsafe_b64encode(salt).decode("ascii"),
            base64.urlsafe_b64encode(digest).decode("ascii"),
        ]
    )


def verify_password(password: str, encoded: str) -> bool:
    try:
        algorithm, iterations, salt_text, digest_text = encoded.split("$", 3)
        if algorithm != "pbkdf2_sha256":
            return False
        salt = base64.urlsafe_b64decode(salt_text.encode("ascii"))
        expected = base64.urlsafe_b64decode(digest_text.encode("ascii"))
        actual = hashlib.pbkdf2_hmac(
            "sha256",
            password.encode("utf-8"),
            salt,
            int(iterations),
        )
        return hmac.compare_digest(actual, expected)
    except (ValueError, TypeError):
        return False


def _issue_session(session: Session, user: User) -> AuthResponse:
    raw_token = secrets.token_urlsafe(32)
    auth_session = AuthSession(
        user_id=user.id,
        token_hash=hashlib.sha256(raw_token.encode("utf-8")).hexdigest(),
        expires_at=datetime.now(timezone.utc) + timedelta(days=SESSION_DURATION_DAYS),
    )
    session.add(auth_session)
    session.commit()
    session.refresh(user)
    return AuthResponse(
        access_token=raw_token,
        user=user,
        organization=user.organization,
    )


def bootstrap_organization(
    session: Session,
    data: OrganizationBootstrapRequest,
    settings: Optional[Settings] = None,
) -> AuthResponse:
    settings = settings or get_settings()
    email = _normalized_email(data.email)
    if session.scalar(select(User).where(User.email == email)) is not None:
        raise AccountConflictError("Email này đã được sử dụng")
    _consume_registration_otp(session, email, data.otp, settings)

    organization = Organization(
        name=data.company_name.strip(),
        plan_code="business",
        subscription_status="active",
        seat_limit=10,
    )
    owner = User(
        organization=organization,
        email=email,
        full_name=data.owner_name.strip(),
        password_hash=hash_password(data.password),
        role="owner",
        is_active=True,
    )
    session.add_all([organization, owner])
    session.flush()
    return _issue_session(session, owner)


def login(session: Session, data: LoginRequest) -> AuthResponse:
    user = session.scalar(
        select(User)
        .options(selectinload(User.organization))
        .where(User.email == _normalized_email(data.email))
    )
    if user is None or not verify_password(data.password, user.password_hash):
        raise AuthenticationError("Email hoặc mật khẩu không đúng")
    if not user.is_active:
        raise AuthenticationError("Tài khoản đã bị vô hiệu hóa")
    if user.must_change_password and user.temporary_password_expires_at is not None:
        expires_at = user.temporary_password_expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at <= datetime.now(timezone.utc):
            raise AuthenticationError(
                "Mật khẩu tạm đã hết hạn. Vui lòng liên hệ quản trị viên"
            )
    return _issue_session(session, user)


def get_user_by_token(session: Session, token: str) -> User:
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    auth_session = session.scalar(
        select(AuthSession)
        .options(selectinload(AuthSession.user).selectinload(User.organization))
        .where(AuthSession.token_hash == token_hash)
    )
    if auth_session is None:
        raise AuthenticationError("Phiên đăng nhập không hợp lệ")

    expires_at = auth_session.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at <= datetime.now(timezone.utc):
        session.delete(auth_session)
        session.commit()
        raise AuthenticationError("Phiên đăng nhập đã hết hạn")
    if not auth_session.user.is_active:
        raise AuthenticationError("Tài khoản đã bị vô hiệu hóa")
    return auth_session.user


def logout(session: Session, token: str) -> None:
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    auth_session = session.scalar(
        select(AuthSession).where(AuthSession.token_hash == token_hash)
    )
    if auth_session is not None:
        session.delete(auth_session)
        session.commit()


def require_manager(user: User) -> None:
    if user.role not in {"owner", "admin"}:
        raise AuthorizationError("Bạn không có quyền quản lý thành viên")


def list_members(session: Session, actor: User) -> List[User]:
    require_manager(actor)
    return list(
        session.scalars(
            select(User)
            .where(User.organization_id == actor.organization_id)
            .order_by(User.role, User.full_name)
        )
    )


def create_member(
    session: Session,
    actor: User,
    data: MemberCreate,
    settings: Optional[Settings] = None,
    deliver: Optional[Callable[..., None]] = None,
) -> User:
    require_manager(actor)
    if data.role == "admin" and actor.role != "owner":
        raise AuthorizationError("Chỉ chủ sở hữu được cấp quyền admin")
    email = _normalized_email(data.email)
    if session.scalar(select(User).where(User.email == email)) is not None:
        raise AccountConflictError("Email này đã được sử dụng")

    active_members = session.scalar(
        select(func.count(User.id)).where(
            User.organization_id == actor.organization_id,
            User.is_active.is_(True),
        )
    )
    if active_members >= actor.organization.seat_limit:
        raise AccountConflictError("Gói hiện tại đã sử dụng hết số tài khoản")

    user = User(
        organization_id=actor.organization_id,
        email=email,
        full_name=data.full_name.strip(),
        password_hash=hash_password(data.password),
        role=data.role,
        is_active=True,
        must_change_password=True,
        temporary_password_expires_at=(
            datetime.now(timezone.utc) + timedelta(hours=TEMPORARY_PASSWORD_HOURS)
        ),
        created_by_id=actor.id,
    )
    session.add(user)
    settings = settings or get_settings()
    delivery = deliver or send_member_invitation
    try:
        delivery(
            settings,
            email,
            user.full_name,
            actor.organization.name,
            user.role,
            data.password,
        )
        session.commit()
    except Exception:
        session.rollback()
        raise
    session.refresh(user)
    return user


def change_password(
    session: Session,
    user: User,
    data: PasswordChangeRequest,
) -> None:
    if not verify_password(data.current_password, user.password_hash):
        raise AuthenticationError("Mật khẩu hiện tại không đúng")
    if hmac.compare_digest(data.current_password, data.new_password):
        raise AccountConflictError("Mật khẩu mới phải khác mật khẩu tạm")
    user.password_hash = hash_password(data.new_password)
    user.must_change_password = False
    user.temporary_password_expires_at = None
    session.commit()


def update_member(
    session: Session,
    actor: User,
    member_id: uuid.UUID,
    data: MemberUpdate,
) -> User:
    require_manager(actor)
    target = session.get(User, member_id)
    if target is None or target.organization_id != actor.organization_id:
        raise AuthenticationError("Không tìm thấy thành viên")
    if target.role == "owner":
        raise AuthorizationError("Không thể thay đổi tài khoản chủ sở hữu")
    if actor.role == "admin" and (target.role == "admin" or data.role == "admin"):
        raise AuthorizationError("Admin không thể thay đổi quyền admin khác")

    if data.role is not None:
        if data.role == "admin" and actor.role != "owner":
            raise AuthorizationError("Chỉ chủ sở hữu được cấp quyền admin")
        target.role = data.role
    if data.is_active is not None:
        target.is_active = data.is_active
        if not data.is_active:
            session.query(AuthSession).filter(
                AuthSession.user_id == target.id
            ).delete()
    session.commit()
    session.refresh(target)
    return target
