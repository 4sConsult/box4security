"""Create NetworkTypes and SystemTypes

Revision ID: b1685fc5f49c
Revises: 9a02836f6117
Create Date: 2020-10-21 10:01:06.180863

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from source.wizard import SystemType, NetworkType
# revision identifiers, used by Alembic.
revision = 'b1685fc5f49c'
down_revision = '9a02836f6117'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.bulk_insert(SystemType.__table__, [
        {'name': 'BOX4security'},
        {'name': 'DNS-Server'},
        {'name': 'Gateway'},
        {'name': 'Firewall'},
        {'name': 'IoT'},
        {'name': 'Industrielle IT'},
    ])
    op.bulk_insert(NetworkType.__table__, [
        {'name': 'Client'},
        {'name': 'Server'},
        {'name': 'Gast'},
    ])


def downgrade():
    """Downgrade to migration."""
    op.execute(f'DELETE FROM "{SystemType.__table__}" WHERE name="BOX4security"')
    op.execute(f'DELETE FROM "{SystemType.__table__}" WHERE name="DNS-Server"')
    op.execute(f'DELETE FROM "{SystemType.__table__}" WHERE name="Gateway"')
    op.execute(f'DELETE FROM "{SystemType.__table__}" WHERE name="Firewall"')
    op.execute(f'DELETE FROM "{SystemType.__table__}" WHERE name="IoT"')
    op.execute(f'DELETE FROM "{SystemType.__table__}" WHERE name="Industrielle IT"')
    op.execute(f'DELETE FROM "{NetworkType.__table}" WHERE name="Client"')
    op.execute(f'DELETE FROM "{NetworkType.__table}" WHERE name="Server"')
    op.execute(f'DELETE FROM "{NetworkType.__table}" WHERE name="Gast"')
