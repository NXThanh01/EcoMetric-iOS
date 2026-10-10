import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4,
    )
    name: Mapped[str] = mapped_column(String(200))
    plan_code: Mapped[str] = mapped_column(String(32), default="business")
    subscription_status: Mapped[str] = mapped_column(
        String(32),
        default="active",
    )
    seat_limit: Mapped[int] = mapped_column(Integer, default=10)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    users: Mapped[List["User"]] = relationship(
        back_populates="organization",
        cascade="all, delete-orphan",
    )
    facilities: Mapped[List["Facility"]] = relationship(
        back_populates="organization",
    )


class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint(
            "role IN ('owner', 'admin', 'member')",
            name="role_valid",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4,
    )
    organization_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organizations.id", ondelete="CASCADE"),
        index=True,
    )
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(160))
    password_hash: Mapped[str] = mapped_column(String(512))
    role: Mapped[str] = mapped_column(String(16), default="member")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    must_change_password: Mapped[bool] = mapped_column(Boolean, default=False)
    temporary_password_expires_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_by_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    organization: Mapped[Organization] = relationship(back_populates="users")
    sessions: Mapped[List["AuthSession"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )


class AuthSession(Base):
    __tablename__ = "auth_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
    )
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    user: Mapped[User] = relationship(back_populates="sessions")


class RegistrationOTP(Base):
    __tablename__ = "registration_otps"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4,
    )
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    code_hash: Mapped[str] = mapped_column(String(64))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    resend_available_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    consumed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )


class Facility(Base):
    __tablename__ = "facilities"
    __table_args__ = (
        UniqueConstraint(
            "organization_id",
            "name",
            name="uq_facilities_organization_name",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4,
    )
    organization_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organizations.id", ondelete="CASCADE"),
        index=True,
    )
    name: Mapped[str] = mapped_column(String(200))
    timezone: Mapped[str] = mapped_column(
        String(64),
        default="Asia/Ho_Chi_Minh",
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    organization: Mapped[Organization] = relationship(back_populates="facilities")

    meters: Mapped[List["Meter"]] = relationship(
        back_populates="facility",
        cascade="all, delete-orphan",
    )
    datasets: Mapped[List["Dataset"]] = relationship(
        back_populates="facility",
        cascade="all, delete-orphan",
    )


class Meter(Base):
    __tablename__ = "meters"
    __table_args__ = (
        UniqueConstraint(
            "facility_id",
            "name",
            name="uq_meters_facility_name",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4,
    )
    facility_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("facilities.id", ondelete="CASCADE"),
        index=True,
    )
    name: Mapped[str] = mapped_column(String(200))
    data_type: Mapped[str] = mapped_column(String(32), default="electricity")
    unit: Mapped[str] = mapped_column(String(32), default="kWh")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    facility: Mapped[Facility] = relationship(back_populates="meters")
    datasets: Mapped[List["Dataset"]] = relationship(back_populates="meter")


class Dataset(Base):
    __tablename__ = "datasets"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid,
        primary_key=True,
        default=uuid.uuid4,
    )
    facility_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("facilities.id", ondelete="CASCADE"),
        index=True,
    )
    meter_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("meters.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    source_type: Mapped[str] = mapped_column(String(32))
    interval: Mapped[str] = mapped_column(String(16))
    status: Mapped[str] = mapped_column(String(32), default="ready")
    operational_context: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    desired_outcome: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )
    record_count: Mapped[int] = mapped_column(Integer, default=0)
    period_start: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    period_end: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    facility: Mapped[Facility] = relationship(back_populates="datasets")
    meter: Mapped[Optional[Meter]] = relationship(back_populates="datasets")
    measurements: Mapped[List["Measurement"]] = relationship(
        back_populates="dataset",
        cascade="all, delete-orphan",
        order_by="Measurement.timestamp",
    )


class Measurement(Base):
    __tablename__ = "measurements"
    __table_args__ = (
        UniqueConstraint(
            "dataset_id",
            "timestamp",
            name="uq_measurements_dataset_timestamp",
        ),
        CheckConstraint(
            "consumption_kwh >= 0",
            name="consumption_non_negative",
        ),
        CheckConstraint(
            "operating_hours IS NULL OR "
            "(operating_hours > 0 AND operating_hours <= 24)",
            name="operating_hours_range",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    dataset_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("datasets.id", ondelete="CASCADE"),
        index=True,
    )
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    consumption_kwh: Mapped[Decimal] = mapped_column(Numeric(16, 4))
    production_units: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(16, 4),
        nullable=True,
    )
    operating_hours: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(8, 2),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    dataset: Mapped[Dataset] = relationship(back_populates="measurements")
