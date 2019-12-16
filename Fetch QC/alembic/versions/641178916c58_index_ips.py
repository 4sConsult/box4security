"""Index IPs

Revision ID: 641178916c58
Revises: fb3e40f1b833
Create Date: 2019-09-17 14:45:45.581457

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '641178916c58'
down_revision = 'fb3e40f1b833'
branch_labels = None
depends_on = None


def upgrade():
    op.create_index('ik_system_ip', 'system', ['ip'])
    op.create_index('ik_network_ip', 'network', ['ip'])


def downgrade():
    op.drop_index('ik_system_ip')
    op.drop_index('ik_network_ip')
