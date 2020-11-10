"""system and types

Revision ID: 9a02836f6117
Revises: 5aadb38f6936
Create Date: 2020-10-21 09:40:39.988041

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '9a02836f6117'
down_revision = '5aadb38f6936'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.create_table(
        'system',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=True),
        sa.Column('ip_address', sa.String(length=24), nullable=True),
        sa.Column('location', sa.String(length=255), nullable=True),
        sa.Column('scan_enabled', sa.Boolean(), nullable=True),
        sa.Column('ids_enabled', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name')
    )
    op.create_table(
        'systemtype',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_table(
        'system_systemtype',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('system_id', sa.Integer(), nullable=True),
        sa.Column('systemtype_id', sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(['system_id'], ['system.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['systemtype_id'], ['systemtype.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )


def downgrade():
    """Downgrade to migration."""
    op.drop_table('system_systemtype')
    op.drop_table('systemtype')
    op.drop_table('system')
