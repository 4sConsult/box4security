"""Create NetworkTypes and SystemTypes

Revision ID: b1685fc5f49c
Revises: 9a02836f6117
Create Date: 2020-10-21 10:01:06.180863

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from source.wizard.models import SystemType, NetworkType, ScanCategory
# revision identifiers, used by Alembic.
revision = 'b1685fc5f49c'
down_revision = '9a02836f6117'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.bulk_insert(SystemType.__table__, [
        {'id': 1, 'name': 'BOX4security'},
        {'id': 2, 'name': 'DNS-Server'},
        {'id': 3, 'name': 'Gateway'},
        {'id': 4, 'name': 'Firewall'},
        {'id': 5, 'name': 'IoT'},
        {'id': 6, 'name': 'Industrielle IT'},
    ])
    op.bulk_insert(NetworkType.__table__, [
        {'name': 'Client'},
        {'name': 'Server'},
        {'name': 'Gast'},
    ])
    op.bulk_insert(ScanCategory.__table__, [
        {'id': 1, 'name': 'Keine Restriktionen bei den Scans'},
        {'id': 2, 'name': 'Scans ausschließlich zu Randzeiten oder am Wochenende'},
        {'id': 3, 'name': 'Scans ausschließlich bei Einsatzbereitschaft von 4sConsult und Präsenz der Netzwerkadministration'},
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

    op.execute(f'DELETE FROM "{ScanCategory.__table}" WHERE id="1"')
    op.execute(f'DELETE FROM "{ScanCategory.__table}" WHERE id="2"')
    op.execute(f'DELETE FROM "{ScanCategory.__table}" WHERE id="3"')
