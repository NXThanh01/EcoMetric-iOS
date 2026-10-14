"""Lưu báo cáo AI và công việc theo bộ dữ liệu."""
from alembic import op
import sqlalchemy as sa

revision = "20261014_0007"
down_revision = "20261012_0006"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("dataset_insights",
        sa.Column("dataset_id", sa.Uuid(), sa.ForeignKey("datasets.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False))
    op.create_table("action_tasks",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("dataset_id", sa.Uuid(), sa.ForeignKey("datasets.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(160), nullable=False),
        sa.Column("assignee_email", sa.String(320)),
        sa.Column("due_date", sa.DateTime(timezone=True)),
        sa.Column("status", sa.String(24), nullable=False),
        sa.Column("verification_metric", sa.String(300), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False))
    op.create_index("ix_action_tasks_dataset_id", "action_tasks", ["dataset_id"])


def downgrade():
    op.drop_table("action_tasks")
    op.drop_table("dataset_insights")
