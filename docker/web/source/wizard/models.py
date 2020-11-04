from source.extensions import db


class Network(db.Model):
    """Network model class.

    Explanation of non-trivial fields:
    scan_category: Scan Category as defined before:
        1: No restrictions
        2: Scans only at weekend or non-busy times
        3: Scans only when admins and 4s are available
    scan_weekday: lower cased weekday for scans
    scan_time: start time for the scan on `scan_weekday`
    types: List of associated NetworkTypes
    """
    __tablename__ = 'network'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(100))  # Network Name
    ip_address = db.Column(db.String(24), nullable=False)  # Network Address
    cidr = db.Column(db.Integer(), nullable=False)  # CIDR-Number
    vlan = db.Column(db.String(50))  # VLAN Tag
    types = db.relationship('NetworkType', secondary='network_networktype')
    scancategory_id = db.Column(db.Integer, db.ForeignKey('scancategory.id'))
    scan_weekday = db.Column(db.String(24))  # lower case
    scan_time = db.Column(db.Time())  # Start time for scan
    systems = db.relationship('System', backref='network')
    boxes4security = db.relationship('BOX4security', backref='network')

    def __repr__(self):
        """Print Network in human readable form."""
        return '{} ({}): {}/{}'.format(self.name, self.id, self.ip_address, self.cidr)


class ScanCategory(db.Model):
    """Model class for Vulnerability Scan Categories."""
    __tablename__ = 'scancategory'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String())
    networks = db.relationship('Network', backref='scan_category')

    def __repr__(self):
        """Print ScanCategory in human readable form."""
        return '{} ({})'.format(self.name, self.id)


class NetworkType(db.Model):
    """Model class for Network Types."""
    __tablename__ = 'networktype'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(100))  # Network Type Name

    def __repr__(self):
        """Print NetworkType in human readable form."""
        return '{} ({})'.format(self.name, self.id)


class NetworkNetworkType(db.Model):
    """Association table for Network Types and Networks."""
    __tablename__ = 'network_networktype'
    id = db.Column(db.Integer(), primary_key=True)
    network_id = db.Column(db.Integer(), db.ForeignKey('network.id', ondelete='CASCADE'))
    networktype_id = db.Column(db.Integer(), db.ForeignKey('networktype.id', ondelete='CASCADE'))


class System(db.Model):
    """System model class.

    Explanation of non-trivial fields:
    scan_enabled: True if vulnerability scans should be enabled for the system, else False
    ids_enabled: True if IDS should be enabled for the system, else False
    types: List of associated SystemTypes
    """
    __tablename__ = 'system'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(100), unique=True)
    ip_address = db.Column(db.String(24))  # System IP Address
    types = db.relationship('SystemType', secondary='system_systemtype')
    location = db.Column(db.String(255))  # System Location
    scan_enabled = db.Column(db.Boolean(), default=True)  # Scans active
    ids_enabled = db.Column(db.Boolean(), default=True)  # IDS enabled
    network_id = db.Column(db.Integer, db.ForeignKey('network.id'))


class SystemType(db.Model):
    """Model class for System Types."""
    __tablename__ = 'systemtype'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(100))  # System Type Name

    def __repr__(self):
        """Print SystemType in human readable form."""
        return '{} ({})'.format(self.name, self.id)


class SystemSystemType(db.Model):
    """Association table for System Types and Systems."""
    __tablename__ = 'system_systemtype'
    id = db.Column(db.Integer(), primary_key=True)
    system_id = db.Column(db.Integer(), db.ForeignKey('system.id', ondelete='CASCADE'))
    systemtype_id = db.Column(db.Integer(), db.ForeignKey('systemtype.id', ondelete='CASCADE'))


class BOX4securitySystemType(db.Model):
    """Association table for System Types and BOX4security."""
    __tablename__ = 'box4security_systemtype'
    id = db.Column(db.Integer(), primary_key=True)
    box4security = db.Column(db.Integer(), db.ForeignKey('box4security.id', ondelete='CASCADE'))
    systemtype_id = db.Column(db.Integer(), db.ForeignKey('systemtype.id', ondelete='CASCADE'))


class BOX4security(db.Model):
    """Extension of BOX4security model."""
    __tablename__ = 'box4security'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(100), unique=True)
    ip_address = db.Column(db.String(24))  # BOX4security IP Address
    types = db.relationship('SystemType', secondary='box4security_systemtype')
    location = db.Column(db.String(255))  # BOX4security Location
    scan_enabled = db.Column(db.Boolean(), default=False)  # Scans active
    ids_enabled = db.Column(db.Boolean(), default=False)  # IDS enabled
    network_id = db.Column(db.Integer, db.ForeignKey('network.id'))
    dns_id = db.Column(db.Integer, db.ForeignKey('system.id'))
    gateway_id = db.Column(db.Integer, db.ForeignKey('system.id'))
    dns = db.relationship('System', foreign_keys=[dns_id], uselist=False)
    gateway = db.relationship('System', foreign_keys=[gateway_id], uselist=False)
    dhcp_enabled = db.Column(db.Boolean(), default=False)  # dhcp enabled

    def __repr__(self):
        return f"BOX4s ({self.ip_address}) DNS:{self.dns.ip_address} Gateway:{self.gateway.ip_address}"


class WizardState(db.Model):
    """Model to represent the current state the wizard is in."""
    __tablename__ = 'wizardstate'
    id = db.Column(db.Integer(), primary_key=True)
    state_id = db.Column(db.ForeignKey('wizardstatenames.id'), nullable=False)

    def __repr__(self) -> str:
        return f"Wizard State: {self.state.name}"


class WizardStateNames(db.Model):
    """Model to assign changeable names to state ids."""
    __tablename__ = 'wizardstatenames'
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String())
    stateObj = db.relationship('WizardState', backref="state", uselist=False)
