"""Module to provide all models."""
from source.extensions import db, ma
from marshmallow import fields
from flask_user import UserMixin


class User(db.Model, UserMixin):
    """User class to handle authentication and authorization.

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
    roles = db.relationship('Role', secondary='user_role')

    def has_role(self, role):
        # For each role the user has, check, if the given role is actually in the users roles
        # But if the user is a super admin, always return true, as they are allowed to to everything
        for r in self.roles:
            if r.name == role or r.name == "Super Admin":
                return True
        return False

    def getName(self):
        """Return name of current user or email if no name exists."""
        if self.last_name:
            return " ".join(filter(None, [self.first_name, self.last_name]))
        else:
            return self.email


class Role(db.Model):
    """Role class for defining permissions."""

    __tablename__ = 'role'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(50), unique=True)
    description = db.Column(db.String(255))

    def __repr__(self):
        """Print Role in human readable form."""
        return '"{}": "{}"'.format(self.name, self.description)


class UserRole(db.Model):
    """Association table for Users and Roles."""

    __tablename__ = 'user_role'
    id = db.Column(db.Integer(), primary_key=True)
    user_id = db.Column(db.Integer(), db.ForeignKey('user.id', ondelete='CASCADE'))
    role_id = db.Column(db.Integer(), db.ForeignKey('role.id', ondelete='CASCADE'))


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


class RoleSchema(ma.Schema):
    """Role Schema for API representation."""

    class Meta:
        """Define fields which will be available."""

        fields = ('id', 'name', 'description')


class UserSchema(ma.Schema):
    """User Schema for API representation."""

    roles = fields.Nested(RoleSchema, many=True)

    class Meta:
        """Define fields which will be available."""

        fields = ('id', 'email', 'first_name', 'last_name', 'active', 'email_confirmed_at', 'roles')


USR = UserSchema()
BPF = BPFSchema()
LSR = LSRSchema()
BPFs = BPFSchema(many=True)
LSRs = LSRSchema(many=True)
