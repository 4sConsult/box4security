"""Create NetworkTypes and SystemTypes

Revision ID: b1685fc5f49c
Revises: 9a02836f6117
Create Date: 2020-10-21 10:01:06.180863

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from source.wizard import SystemType
# revision identifiers, used by Alembic.
revision = 'b1685fc5f49c'
down_revision = '9a02836f6117'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.bulk_insert(SystemType.__table__, [{'name': 'BOX4security'}, ])


def downgrade():
    """Downgrade to migration."""
    op.execute('DELETE FROM "systemtype" WHERE name="BOX4security"')
