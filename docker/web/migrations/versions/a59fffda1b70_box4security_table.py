"""BOX4security table

Revision ID: a59fffda1b70
Revises: ea1ce32ce8fd
Create Date: 2020-10-29 08:20:06.251992

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'a59fffda1b70'
down_revision = 'ea1ce32ce8fd'
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade to migration."""
    op.create_table(
        'box4security',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=True),
        sa.Column('ip_address', sa.String(length=24), nullable=True),
        sa.Column('location', sa.String(length=255), nullable=True),
        sa.Column('scan_enabled', sa.Boolean(), nullable=True),
        sa.Column('ids_enabled', sa.Boolean(), nullable=True),
        sa.Column('network_id', sa.Integer(), nullable=True),
        sa.Column('dns_id', sa.Integer(), nullable=True),
        sa.Column('gateway_id', sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(['dns_id'], ['system.id'], ),
        sa.ForeignKeyConstraint(['gateway_id'], ['system.id'], ),
        sa.ForeignKeyConstraint(['network_id'], ['network.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('name')
    )
    op.create_table(
        'box4security_systemtype',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('box4security', sa.Integer(), nullable=True),
        sa.Column('systemtype_id', sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(['box4security'], ['box4security.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['systemtype_id'], ['systemtype.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.drop_constraint('system_gateway_id_fkey', 'system', type_='foreignkey')
    op.drop_constraint('system_dns_id_fkey', 'system', type_='foreignkey')
    op.drop_column('system', 'dns_id')
    op.drop_column('system', 'gateway_id')


def downgrade():
    """Downgrade to migration."""
    op.add_column('system', sa.Column('gateway_id', sa.INTEGER(), autoincrement=False, nullable=True))
    op.add_column('system', sa.Column('dns_id', sa.INTEGER(), autoincrement=False, nullable=True))
    op.create_foreign_key('system_dns_id_fkey', 'system', 'system', ['dns_id'], ['id'])
    op.create_foreign_key('system_gateway_id_fkey', 'system', 'system', ['gateway_id'], ['id'])
    op.drop_table('box4security_systemtype')
    op.drop_table('box4security')
