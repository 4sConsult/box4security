import sqlalchemy as sa
from sqlalchemy.ext.declarative import declarative_base
Base = sa.ext.declarative.declarative_base()

association_table = sa.Table(
    'systemsystemtype',
    Base.metadata,
    sa.Column('system_id', sa.Integer, sa.ForeignKey('system.id')),
    sa.Column('systemtype_id', sa.Integer, sa.ForeignKey('systemtype.id'))
)

# TODO: Ansprechpartner Tabelle mit Link zu Branch


class Branch(Base):
    __tablename__ = 'branch'
    id = sa.Column(sa.Integer, primary_key=True)
    bicompanyid = sa.Column(sa.Integer)  # THE COMPANY ID FROM BI / BACKEND
    name = sa.Column(sa.String)
    street = sa.Column(sa.String)
    house = sa.Column(sa.String)
    postalcode = sa.Column(sa.String)
    city = sa.Column(sa.String)
    country = sa.Column(sa.String)
    # TODO: Link to BOX of Branch
    # TODO: Link to Networks of Branch

    def __repr__(self):
        return f"#{self.id}: {self.name}, {self.street} {self.house}, {self.postalcode} {self.city}, {self.country} - (BI-ID:{self.bicompanyid})"


class Network(Base):
    __tablename__ = 'network'
    id = sa.Column(sa.Integer, primary_key=True)
    ip = sa.Column(sa.String, index=True)
    cidr = sa.Column(sa.String)
    type = sa.Column(sa.String)
    purpose = sa.Column(sa.String)

    @classmethod
    def _fromdict(cls, netdict):
        return cls(
            ip=netdict['ip'],
            cidr=netdict['cidr'],
            type=netdict['type'],
            purpose=netdict['purpose'] if 'purpose' in netdict else None,
        )

    def __repr__(self):
        return "{ip}/{cidr}: {type} {purpose}".format(ip=self.ip, cidr=self.cidr, type=self.type, purpose=self.purpose)


class SystemType(Base):
    __tablename__ = 'systemtype'
    id = sa.Column(sa.Integer, primary_key=True)
    name = sa.Column(sa.String)

    def __repr__(self):
        return self.name


class System(Base):
    __tablename__ = 'system'
    id = sa.Column(sa.Integer, primary_key=True)
    ip = sa.Column(sa.String, index=True)
    types = sa.orm.relationship('SystemType', secondary=association_table)
    noscan = sa.Column(sa.Boolean)
    notrack = sa.Column(sa.Boolean)
    purpose = sa.Column(sa.String)

    @classmethod
    def _fromdict(cls, sysdict):
        return cls(
            ip=sysdict['ip'],
            types=[i for i in sysdict['types'] if sysdict['types'].__class__ == SystemType],
            noscan=sysdict['noscan'],
            notrack=sysdict['notrack'],
            purpose=sysdict['purpose'] if 'purpose' in sysdict else None,
        )

    def __repr__(self):
        return "{ip}: {types} NOSCAN: {noscan} NOTRACK: {notrack} {purpose}".format(
            ip=self.ip, types=self.types, noscan=self.noscan, notrack=self.notrack, purpose=self.purpose)
