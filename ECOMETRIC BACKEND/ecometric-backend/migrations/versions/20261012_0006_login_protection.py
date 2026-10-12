"""Thêm bảo vệ chống dò mật khẩu cho tài khoản.

Revision ID: 20261012_0006
Revises: 20261010_0005
Create Date: 2026-10-12
"""
from typing import Optional, Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20261012_0006"
down_revision: Optional[str] = "20261010_0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "failed_login_attempts",
            sa.Integer(),
            server_default="0",
            nullable=False,
        ),
    )
    op.add_column(
        "users",
        sa.Column("locked_until", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "locked_until")
    op.drop_column("users", "failed_login_attempts")
