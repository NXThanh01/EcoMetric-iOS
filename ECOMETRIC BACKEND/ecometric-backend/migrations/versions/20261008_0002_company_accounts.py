"""Tạo tổ chức, tài khoản và phân quyền doanh nghiệp.

Revision ID: 20261008_0002
Revises: 20261007_0001
Create Date: 2026-10-08
"""
from typing import Optional, Sequence, Union
import uuid

from alembic import op
import sqlalchemy as sa


revision: str = "20261008_0002"
down_revision: Optional[str] = "20261007_0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

LEGACY_ORGANIZATION_ID = "00000000-0000-0000-0000-000000000001"


def upgrade() -> None:
    op.create_table(
        "organizations",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=200), nullable=False),
        sa.Column("plan_code", sa.String(length=32), nullable=False),
        sa.Column("subscription_status", sa.String(length=32), nullable=False),
        sa.Column("seat_limit", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id", name="pk_organizations"),
    )

    op.execute(
        sa.text(
            "INSERT INTO organizations "
            "(id, name, plan_code, subscription_status, seat_limit) "
            "VALUES (:id, :name, 'business', 'active', 10)"
        ).bindparams(
            sa.bindparam(
                "id",
                value=uuid.UUID(LEGACY_ORGANIZATION_ID),
                type_=sa.Uuid(),
            ),
            name="Dữ liệu EcoMetric hiện có",
        )
    )

    op.add_column(
        "facilities",
        sa.Column("organization_id", sa.Uuid(), nullable=True),
    )
    op.execute(
        sa.text(
            "UPDATE facilities SET organization_id = :organization_id "
            "WHERE organization_id IS NULL"
        ).bindparams(
            sa.bindparam(
                "organization_id",
                value=uuid.UUID(LEGACY_ORGANIZATION_ID),
                type_=sa.Uuid(),
            )
        )
    )
    op.alter_column("facilities", "organization_id", nullable=False)
    op.create_foreign_key(
        "fk_facilities_organization_id_organizations",
        "facilities",
        "organizations",
        ["organization_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index(
        "ix_facilities_organization_id",
        "facilities",
        ["organization_id"],
    )
    op.drop_constraint("uq_facilities_name", "facilities", type_="unique")
    op.create_unique_constraint(
        "uq_facilities_organization_name",
        "facilities",
        ["organization_id", "name"],
    )

    op.create_table(
        "users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("organization_id", sa.Uuid(), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("full_name", sa.String(length=160), nullable=False),
        sa.Column("password_hash", sa.String(length=512), nullable=False),
        sa.Column("role", sa.String(length=16), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_by_id", sa.Uuid(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "role IN ('owner', 'admin', 'member')",
            name="ck_users_role_valid",
        ),
        sa.ForeignKeyConstraint(
            ["created_by_id"],
            ["users.id"],
            name="fk_users_created_by_id_users",
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["organization_id"],
            ["organizations.id"],
            name="fk_users_organization_id_organizations",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_users"),
        sa.UniqueConstraint("email", name="uq_users_email"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_organization_id", "users", ["organization_id"])

    op.create_table(
        "auth_sessions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["user_id"],
            ["users.id"],
            name="fk_auth_sessions_user_id_users",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_auth_sessions"),
        sa.UniqueConstraint("token_hash", name="uq_auth_sessions_token_hash"),
    )
    op.create_index(
        "ix_auth_sessions_token_hash",
        "auth_sessions",
        ["token_hash"],
        unique=True,
    )
    op.create_index("ix_auth_sessions_user_id", "auth_sessions", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_auth_sessions_user_id", table_name="auth_sessions")
    op.drop_index("ix_auth_sessions_token_hash", table_name="auth_sessions")
    op.drop_table("auth_sessions")
    op.drop_index("ix_users_organization_id", table_name="users")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
    op.drop_constraint(
        "uq_facilities_organization_name",
        "facilities",
        type_="unique",
    )
    op.create_unique_constraint("uq_facilities_name", "facilities", ["name"])
    op.drop_index("ix_facilities_organization_id", table_name="facilities")
    op.drop_constraint(
        "fk_facilities_organization_id_organizations",
        "facilities",
        type_="foreignkey",
    )
    op.drop_column("facilities", "organization_id")
    op.drop_table("organizations")
