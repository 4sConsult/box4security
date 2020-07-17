"""Add Role 'Config'

Revision ID: 96cfbddbc495
Revises: 9f79000ab53d
Create Date: 2020-07-17 12:23:24.189549

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from source.models import Role

# revision identifiers, used by Alembic.
revision = '96cfbddbc495'
down_revision = '9f79000ab53d'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.bulk_insert(Role.__table__,
                   [
                       {'id': 13, 'name': 'Config', 'description': 'Einsicht und Bearbeiten der BOX4s-Konfiguration'},
                   ])


def downgrade():
    """Downgrade to migration."""
    op.execute('DELETE FROM "role" WHERE id=13')
