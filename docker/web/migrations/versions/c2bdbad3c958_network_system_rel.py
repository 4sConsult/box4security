"""Relation Network <-> Systems

Revision ID: c2bdbad3c958
Revises: b1685fc5f49c
Create Date: 2020-10-27 08:26:08.007801

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'c2bdbad3c958'
down_revision = 'b1685fc5f49c'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.add_column('system', sa.Column('network_id', sa.Integer(), nullable=True))
    op.create_foreign_key(None, 'system', 'network', ['network_id'], ['id'])


def downgrade():
    """Downgrade to migration."""
    op.drop_constraint(None, 'system', type_='foreignkey')
    op.drop_column('system', 'network_id')
