"""empty message

Revision ID: 532110801da9
Revises:
Create Date: 2020-04-16 14:31:23.045988

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '532110801da9'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    """Create Users table."""
    op.create_table(
        'user',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default='1', nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('email_confirmed_at', sa.DateTime(), nullable=True),
        sa.Column('password', sa.String(length=255), server_default='', nullable=False),
        sa.Column('first_name', sa.String(length=100), server_default='', nullable=False),
        sa.Column('last_name', sa.String(length=100), server_default='', nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('email'),
    )


def downgrade():
    """Drop Users table."""
    op.drop_table('user')
    # ### end Alembic commands ###
