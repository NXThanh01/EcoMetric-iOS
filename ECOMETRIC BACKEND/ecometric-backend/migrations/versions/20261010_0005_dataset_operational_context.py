"""Thêm bối cảnh vận hành và mục tiêu cho bộ dữ liệu.

Revision ID: 20261010_0005
Revises: 20261009_0004
Create Date: 2026-10-10
"""
from typing import Optional, Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20261010_0005"
down_revision: Optional[str] = "20261009_0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "datasets",
        sa.Column("operational_context", sa.Text(), nullable=True),
    )
    op.add_column(
        "datasets",
        sa.Column("desired_outcome", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("datasets", "desired_outcome")
    op.drop_column("datasets", "operational_context")
