"""BOX4s: DHCP col

Revision ID: d995a93c3a9c
Revises: a59fffda1b70
Create Date: 2020-10-30 07:24:16.155013

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'd995a93c3a9c'
down_revision = 'a59fffda1b70'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.add_column('box4security', sa.Column('dhcp_enabled', sa.Boolean(), nullable=True))


def downgrade():
    """Downgrade to migration."""
    op.drop_column('box4security', 'dhcp_enabled')
