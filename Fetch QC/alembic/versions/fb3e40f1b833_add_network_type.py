"""Add network type

Revision ID: fb3e40f1b833
Revises: 770da192e056
Create Date: 2019-09-17 12:03:45.082151

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'fb3e40f1b833'
down_revision = '770da192e056'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('network', sa.Column('type', sa.String))


def downgrade():
    pass
