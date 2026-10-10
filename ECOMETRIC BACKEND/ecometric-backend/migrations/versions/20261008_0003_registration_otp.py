"""Thêm mã OTP xác minh email khi đăng ký doanh nghiệp.

Revision ID: 20261008_0003
Revises: 20261008_0002
Create Date: 2026-10-08
"""
from typing import Optional, Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20261008_0003"
down_revision: Optional[str] = "20261008_0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "registration_otps",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("code_hash", sa.String(length=64), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "resend_available_at",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column("consumed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id", name="pk_registration_otps"),
    )
    op.create_index(
        "ix_registration_otps_email",
        "registration_otps",
        ["email"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("ix_registration_otps_email", table_name="registration_otps")
    op.drop_table("registration_otps")
