"""Branch Table

Revision ID: db1c8858e32c
Revises: 641178916c58
Create Date: 2019-09-18 15:16:18.001866

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import Column, ForeignKey, Integer, String, Boolean


# revision identifiers, used by Alembic.
revision = 'db1c8858e32c'
down_revision = '641178916c58'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('branch', Column('id', Integer, primary_key=True), Column('bicompanyid', Integer), Column('name', String),
                    Column('street', String), Column('house', String), Column('city', String), Column('postalcode', String),
                    Column('city', String), Column('country', String))


def downgrade():
    op.drop_table('branch')
