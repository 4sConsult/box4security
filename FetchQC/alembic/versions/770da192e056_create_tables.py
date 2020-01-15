"""create tables

Revision ID: 770da192e056
Revises:
Create Date: 2019-09-17 11:55:57.944030

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import Column, ForeignKey, Integer, String, Boolean


# revision identifiers, used by Alembic.
revision = '770da192e056'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('network', Column('id', Integer, primary_key=True), Column('ip', String),
                    Column('cidr', String), Column('purpose', String))
    op.create_table('systemtype', Column('id', Integer, primary_key=True), Column('name', String))
    op.create_table('system', Column('id', Integer, primary_key=True), Column('ip', String), Column('name', String),
                    Column('noscan', Boolean), Column('notrack', Boolean), Column('purpose', String))

    op.create_table(
    'systemsystemtype',
    Column('system_id', Integer, ForeignKey('system.id')),
    Column('systemtype_id', Integer, ForeignKey('systemtype.id'))
    )
def downgrade():
    pass
