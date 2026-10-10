"""Tạo schema dữ liệu vận hành ban đầu.

Revision ID: 20261007_0001
Revises:
Create Date: 2026-10-07
"""
from typing import Optional, Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20261007_0001"
down_revision: Optional[str] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "facilities",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("timezone", sa.String(length=64), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id", name="pk_facilities"),
        sa.UniqueConstraint("name", name="uq_facilities_name"),
    )
    op.create_table(
        "meters",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("facility_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("data_type", sa.String(length=32), nullable=False),
        sa.Column("unit", sa.String(length=32), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["facility_id"],
            ["facilities.id"],
            name="fk_meters_facility_id_facilities",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_meters"),
        sa.UniqueConstraint(
            "facility_id",
            "name",
            name="uq_meters_facility_name",
        ),
    )
    op.create_index("ix_meters_facility_id", "meters", ["facility_id"])
    op.create_table(
        "datasets",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("facility_id", sa.Uuid(), nullable=False),
        sa.Column("meter_id", sa.Uuid(), nullable=True),
        sa.Column("source_type", sa.String(length=32), nullable=False),
        sa.Column("interval", sa.String(length=16), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("record_count", sa.Integer(), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=True),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["facility_id"],
            ["facilities.id"],
            name="fk_datasets_facility_id_facilities",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["meter_id"],
            ["meters.id"],
            name="fk_datasets_meter_id_meters",
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_datasets"),
    )
    op.create_index("ix_datasets_facility_id", "datasets", ["facility_id"])
    op.create_index("ix_datasets_meter_id", "datasets", ["meter_id"])
    op.create_table(
        "measurements",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("dataset_id", sa.Uuid(), nullable=False),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("consumption_kwh", sa.Numeric(16, 4), nullable=False),
        sa.Column("production_units", sa.Numeric(16, 4), nullable=True),
        sa.Column("operating_hours", sa.Numeric(8, 2), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "consumption_kwh >= 0",
            name="ck_measurements_consumption_non_negative",
        ),
        sa.CheckConstraint(
            "operating_hours IS NULL OR "
            "(operating_hours > 0 AND operating_hours <= 24)",
            name="ck_measurements_operating_hours_range",
        ),
        sa.ForeignKeyConstraint(
            ["dataset_id"],
            ["datasets.id"],
            name="fk_measurements_dataset_id_datasets",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_measurements"),
        sa.UniqueConstraint(
            "dataset_id",
            "timestamp",
            name="uq_measurements_dataset_timestamp",
        ),
    )
    op.create_index(
        "ix_measurements_dataset_id",
        "measurements",
        ["dataset_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_measurements_dataset_id", table_name="measurements")
    op.drop_table("measurements")
    op.drop_index("ix_datasets_meter_id", table_name="datasets")
    op.drop_index("ix_datasets_facility_id", table_name="datasets")
    op.drop_table("datasets")
    op.drop_index("ix_meters_facility_id", table_name="meters")
    op.drop_table("meters")
    op.drop_table("facilities")
