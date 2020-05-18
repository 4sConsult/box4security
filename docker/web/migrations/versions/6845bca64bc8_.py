"""Wiki

Revision ID: 6845bca64bc8
Revises: 1d03ea9e33bd
Create Date: 2020-05-18 10:22:11.938319

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from source.models import Role

# revision identifiers, used by Alembic.
revision = '6845bca64bc8'
down_revision = '1d03ea9e33bd'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.bulk_insert(Role.__table__,
                   [
                       {'id': 11, 'name': 'Wiki', 'description': 'Freigabe für die Dokumentation'},
                   ])


def downgrade():
    """Downgrade to migration."""
    op.execute('DELETE FROM "role" WHERE id=11')
