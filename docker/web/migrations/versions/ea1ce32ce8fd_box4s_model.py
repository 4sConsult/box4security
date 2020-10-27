"""BOX4security model and relation to system

Revision ID: ea1ce32ce8fd
Revises: c2bdbad3c958
Create Date: 2020-10-27 09:18:08.417000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'ea1ce32ce8fd'
down_revision = 'c2bdbad3c958'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.add_column('system', sa.Column('dns_id', sa.Integer()))
    op.add_column('system', sa.Column('gateway_id', sa.Integer()))
    op.create_foreign_key(None, 'system', 'system', ['gateway_id'], ['id'])
    op.create_foreign_key(None, 'system', 'system', ['dns_id'], ['id'])


def downgrade():
    """Downgrade to migration."""
    op.drop_constraint(None, 'system', type_='foreignkey')
    op.drop_constraint(None, 'system', type_='foreignkey')
    op.drop_column('system', 'gateway_id')
    op.drop_column('system', 'dns_id')
