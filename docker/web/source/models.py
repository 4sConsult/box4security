"""Module to provide all models."""
from source.extensions import db, ma
from flask_user import UserMixin


class User(db.Model, UserMixin):
    u"""User class to handle authentication and authorization.

    active: can login e.g. not banned
    email_confirmed_at: Zeitstempel, an dem die E-Mail bestätigt wurde
    roles: Liste der, dem User zugeorndeten Regeln
    """

    __tablename__ = 'user'
    id = db.Column(db.Integer, primary_key=True)
    active = db.Column('is_active', db.Boolean(), nullable=False, server_default='1')

    # User authentication information. The collation='NOCASE' is required
    # to search case insensitively when USER_IFIND_MODE is 'nocase_collation'.
    email = db.Column(db.String(255), nullable=False, unique=True)
    email_confirmed_at = db.Column(db.DateTime())
    password = db.Column(db.String(255), nullable=False, server_default='')
    # User information
    first_name = db.Column(db.String(100), nullable=False, server_default='')
    last_name = db.Column(db.String(100), nullable=False, server_default='')

    # Define the relationship to Role via UserRoles
    # roles = db.relationship('Role', secondary='user_roles')


# When in doubt, see:
# https://rahmanfadhil.com/flask-rest-api/
class BPFRule(db.Model):
    __tablename__ = 'blocks_by_bpffilter'
    id = db.Column(db.Integer, primary_key=True)
    src_ip = db.Column(db.String)
    src_port = db.Column(db.Integer)
    dst_ip = db.Column(db.String)
    dst_port = db.Column(db.Integer)
    proto = db.Column(db.String(4))


class LogstashRule(db.Model):
    __tablename__ = 'blocks_by_logstashfilter'
    id = db.Column(db.Integer, primary_key=True)
    src_ip = db.Column(db.String)
    src_port = db.Column(db.Integer)
    dst_ip = db.Column(db.String)
    dst_port = db.Column(db.Integer)
    proto = db.Column(db.String(4))
    signature_id = db.Column(db.String(10))
    signature = db.Column(db.String(256))


class BPFSchema(ma.Schema):
    class Meta:
        fields = ('id', 'src_ip', 'src_port', 'dst_ip', 'dst_port', 'proto')


class LSRSchema(ma.Schema):
    class Meta:
        fields = ('id', 'src_ip', 'src_port', 'dst_ip', 'dst_port', 'proto', 'signature_id', 'signature')


BPF = BPFSchema()
LSR = LSRSchema()
BPFs = BPFSchema(many=True)
LSRs = LSRSchema(many=True)
