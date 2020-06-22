"""Add Alerts

Revision ID: 9f79000ab53d
Revises: 6845bca64bc8
Create Date: 2020-06-19 14:51:24.689902

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from source.models import Role

# revision identifiers, used by Alembic.
revision = '9f79000ab53d'
down_revision = '6845bca64bc8'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.bulk_insert(Role.__table__,
                   [
                       {'id': 12, 'name': 'Alerts', 'description': 'Kontrolle der Alarmierungen'},
                   ])


def downgrade():
    """Downgrade to migration."""
    op.execute('DELETE FROM "role" WHERE id=12')
