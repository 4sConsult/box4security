from flask import redirect, Blueprint, render_template, url_for, request
from flask.helpers import flash
from wtforms_alchemy import ModelForm
from sqlalchemy.exc import SQLAlchemyError
from flask_wtf import FlaskForm
from wtforms import SelectMultipleField, SelectField, TextField
from source.extensions import db, ma
from marshmallow import fields
import os
import shutil
import stat
import tempfile
import re


class WizardMiddleware():
    """BOX4security Wizard Middleware."""
    # Ordered list of steps
    steps = ['wizard.index', 'wizard.networks', 'wizard.systems', 'wizard.box4s', 'wizard.smtp', 'wizard.verify']

    def __init__(self, app):
        self.app = app
        self.url = '/wizard/'

    def __call__(self, environ, start_response):
        """Function is the main function called at each request to the middleware.
        The wizard middleware only applies if isShowWizard() returns true and
        the requested path is not an /api/ path or the wizard path itself.
        If it applies: redirect to self.url ('/wizard').
        If it does not apply, do nothing and pass the request to next middleware.
        """
        reqPath = environ.get('PATH_INFO')
        if self.isShowWizard() and not reqPath.startswith('/api/') and not reqPath.startswith(self.url):
            # If true, redirect to the wizard base URL (self.url) with status code 307
            status = "307 Temporary Redirect"
            headers = [('Location', self.url), ('Content-Length', '0')]
            start_response(status, headers)
            return [b'']
        # if the Wizard shall not be shown, cleanly exit the middleware without doing anything and continue the application flow.
        return self.app(environ, start_response)

    def isShowWizard(self):
        """Evaluate whether the Wizard shall be displayed."""
        return True

    @staticmethod
    def getMaxStep():
        """Return the maximum advanced step as endpoint string.

        For example:
        Returns 'wizard.systems' if the user has recently completed the box4s step but not yet the systems step.
        """
        # DEBUG:
        return 'wizard.verify'
        if BOX4security.query.order_by(BOX4security.id.asc()).count():
            # BOX4security exists, next step is smtp
            return 'wizard.smtp'
        if System.query.count():
            # Systems apart from BOX4s exist, next step is box4s
            return 'wizard.box4s'
        elif Network.query.count():
            # Network is defined, next step BOX4s
            return 'wizard.systems'
        else:
            # Nothing yet defined, max step is networks
            return 'wizard.networks'

    @staticmethod
    def compareSteps(ep1, ep2):
        """Compare two step endpoints.
        Return 0 if ep1 and ep2 are the same step.
        Return -1 if ep1 is an earlier step than ep2.
        Return 1 if ep2 is an earlier step than ep1.
        """
        if ep1 == ep2:
            return 0
        elif WizardMiddleware.steps.index(ep1) < WizardMiddleware.steps.index(ep2):
            return -1
        else:
            return 1


wizard = Blueprint('wizard', __name__, template_folder='templates/wizard')


@wizard.route('/', methods=['GET', 'POST'])
def index():
    return render_template('index.html')


@wizard.route('/networks', methods=['GET', 'POST'])
def networks():
    formNetwork = NetworkForm(request.form)
    formNetwork.types.choices = [(t.id, t.name) for t in NetworkType.query.order_by('id')]
    formNetwork.scancategory_id.choices = [(c.id, c.name) for c in ScanCategory.query.order_by('id')]
    if request.method == 'POST':
        if formNetwork.validate():
            newNetwork = Network()
            formNetwork.populate_obj(newNetwork)  # Copies matching attributes from form onto newNetwork
            newNetwork.types = [NetworkType.query.get(tid) for tid in newNetwork.types]  # Get actual type objects from their IDs
            db.session.add(newNetwork)
            db.session.commit()
            return redirect(url_for('wizard.networks'))
    networks = Network.query.order_by(Network.id.asc()).all()
    scan_categories = ScanCategory.query.order_by(ScanCategory.id.asc()).all()
    return render_template('networks.html', formNetwork=formNetwork, networks=networks, scan_categories=scan_categories)


@wizard.route('/box4s', methods=['GET', 'POST'])
def box4s():
    endpoint = WizardMiddleware.getMaxStep()

    if WizardMiddleware.compareSteps('wizard.box4s', endpoint) < 1:
        formBOX4s = BOX4sForm(request.form)
        formBOX4s.network_id.choices = [(n.id, f"{n.name} ({n.ip_address}/{n.cidr})") for n in Network.query.order_by('id')]
        formBOX4s.dns_id.choices = [(s.id, f"{s.name} ({s.ip_address})") for s in System.query.order_by('id').filter(System.types.any(name='DNS-Server'))]
        formBOX4s.gateway_id.choices = [(s.id, f"{s.name} ({s.ip_address})") for s in System.query.order_by('id').filter(System.types.any(name='Gateway'))]
        BOX4s = BOX4security.query.order_by(BOX4security.id.asc()).first()
        if request.method == 'POST':
            if formBOX4s.validate():
                if not BOX4s:
                    # BOX4s does not exist => create anew.
                    BOX4s = BOX4security()
                formBOX4s.populate_obj(BOX4s)  # Copies matching attributes from form onto box4s
                BOX4s.name = "BOX4security"
                BOX4s.ids_enabled = False
                BOX4s.scan_enabled = False
                BOX4s.types = [SystemType.query.filter(SystemType.name == 'BOX4security').first()]
                BOX4s.dns = System.query.get(BOX4s.dns_id)
                BOX4s.gateway = System.query.get(BOX4s.gateway_id)
                try:
                    db.session.add(BOX4s)
                    db.session.commit()
                except SQLAlchemyError:
                    flash('Die Konfiguration konnte nicht gespeichert werden.', category="error")
                else:
                    flash('Die Konfiguration wurde entgegengenommen.', category="success")
                return redirect(url_for('wizard.box4s'))
        return render_template('box4s.html', formBOX4s=formBOX4s, box4s=BOX4s)
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen. Bitte geben Sie auf der Seite der Systeme mindestens einen DNS-Server sowie einen Gateway an, der für die BOX4security genutzt werden kann.', 'error')
        return redirect(url_for(endpoint))


@wizard.route('/systems', methods=['GET', 'POST'])
def systems():
    endpoint = WizardMiddleware.getMaxStep()
    if WizardMiddleware.compareSteps('wizard.systems', endpoint) < 1:
        formSystem = SystemForm(request.form)
        formSystem.network_id.choices = [(n.id, f"{n.name} ({n.ip_address}/{n.cidr})") for n in Network.query.order_by('id')]
        formSystem.types.choices = [(t.id, t.name) for t in SystemType.query.order_by('id').filter(SystemType.name != 'BOX4security')]
        if request.method == 'POST':
            if formSystem.validate():
                newSystem = System()
                formSystem.populate_obj(newSystem)  # Copies matching attributes from form onto newSystem
                newSystem.types = [SystemType.query.get(tid) for tid in newSystem.types]  # Get actual type objects from their IDs
                db.session.add(newSystem)
                db.session.commit()
                return redirect(url_for('wizard.systems'))
        systems = System.query.order_by(System.id.asc()).all()
        return render_template('systems.html', formSystem=formSystem, systems=systems)
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen.', 'error')
        return redirect(url_for(endpoint))


@wizard.route('/mail', methods=['GET', 'POST'])
def smtp():
    endpoint = WizardMiddleware.getMaxStep()
    if WizardMiddleware.compareSteps('wizard.smtp', endpoint) < 1:
        return render_template('mail.html')
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen.', 'error')
        return redirect(url_for(endpoint))


@wizard.route('/verify', methods=['GET', 'POST'])
def verify():
    endpoint = WizardMiddleware.getMaxStep()
    if WizardMiddleware.compareSteps('wizard.verify', endpoint) < 1:
        if request.method == 'POST':
            apply()
            return render_template('verify_progress.html')
        networks = Network.query.order_by(Network.id.asc()).all()
        systems = System.query.order_by(System.id.asc()).all()
        BOX4s = BOX4security.query.order_by(BOX4security.id.asc()).first()
        scan_categories = ScanCategory.query.order_by(ScanCategory.id.asc()).all()
        return render_template('verify.html', networks=networks, systems=systems, box4s=BOX4s, scan_categories=scan_categories)
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen.', 'error')
        return redirect(url_for(endpoint))


def apply():
    """Apply the configuration."""
    # Step 0: Query Information.
    networks = Network.query.order_by(Network.id.asc()).all()
    systems = System.query.order_by(System.id.asc()).all()
    BOX4s = BOX4security.query.order_by(BOX4security.id.asc()).first()

    # Step 1: Set DNS in resolv.personal
    with open('/var/lib/box4s/resolv.personal', 'w') as fd_resolv:
        fd_resolv.write(f'nameserver {BOX4s.dns.ip_address}\n')
    fd_resolv.close()

    # Step 2: Set INT_IP in /etc/environment
    tmp, tmp_path = tempfile.mkstemp(text=True)
    with open('/etc/environment', 'r') as fd_env:
        with open(tmp, 'w') as fd_tmp:
            for line in fd_env:
                if "KUNDE=" in line:
                    line = "KUNDE={kunde}\n".format(kunde='NEWKUNDE')
                elif "INT_IP=" in line:
                    line = f"INT_IP={BOX4s.ip_address}\n"
                fd_tmp.write(line)
            fd_tmp.seek(0)
        shutil.copyfile(tmp_path, '/etc/environment')
    os.remove(tmp_path)
    fd_env.close()
    # Step 3:

    # Step 4: Apply networks to logstash configuration.

    # Prepare list for IPs to drop and not track (ids_enabled = False)
    drop_systems_iplist = ["f{ip_address}" for ip_address, in db.session.query(System.ip_address).filter(System.ids_enabled is False).all()]
    drop_systems_iplist += ['localhost', '127.0.0.1', '127.0.0.53']
    drop_systems_iplist += [f"{BOX4s.ip_address}"]

    # Render the templates and fill with data
    templateDrop = render_template('logstash/drop.jinja2', iplist=drop_systems_iplist)
    templateNetworks = render_template('logstash/network.jinja2', networks=networks)
    templateSystems = render_template('logstash/system.jinja2', systems=systems)

    # Render the final template from smaller templates.
    templateBOX4sSpecial = render_template('logstash/BOX4s-special.conf.jinja2', templateDrop=templateDrop, templateNetworks=templateNetworks, templateSystems=templateSystems)

    # Write the replaced text to the original file, replacing it.
    with open('/etc/box4s/logstash/BOX4s-special.conf', 'w', encoding='utf-8') as fd_4sspecial:
        fd_4sspecial.write(templateBOX4sSpecial)

    # Step 5: Apply INT_IP to Logstash Default.
    with open('/etc/default/logstash', 'r', encoding='utf-8') as fd_deflogstash:
        content = fd_deflogstash.read()
        content = re.sub(r'(INT_IP=)([0-9\.]+)()', r'\g<1>{}'.format(BOX4s.ip_address), content)
        content = re.sub(r'(KUNDE=)(\w+)()', r'\g<1>{}'.format("NEWKUNDE"), content)
    with open('/etc/default/logstash', 'w', encoding='utf-8') as fd_deflogstash:
        fd_deflogstash.write(content)

    # Step 6: Set network configuration for BOX4security.
    templateNetplan = render_template('logstash/netplan.yaml.jinja2', BOX4s=BOX4s)
    with open('/etc/_netplan/10-BOX4security.yaml', 'w', encoding='utf-8') as fd_netplan:
        fd_netplan.write(templateNetplan)


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


class NetworkTypeSchema(ma.Schema):
    """Role Schema for API representation."""

    class Meta:
        """Define fields which will be available."""

        fields = ('id', 'name')


class ScanCategorySchema(ma.Schema):

    class Meta:
        fields = (
            'id',
            'name',
        )


class NetworkSchema(ma.Schema):

    types = fields.Nested(NetworkTypeSchema, many=True)
    scancategory = fields.Nested(ScanCategorySchema)

    class Meta:
        fields = (
            'id',
            'name',
            'ip_address',
            'cidr',
            'vlan',
            'types',
            'scancategory_id',
            'scan_weekday',
            'scan_time',
        )


NET = NetworkSchema()
NETs = NetworkSchema(many=True)


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


class SystemTypeSchema(ma.Schema):
    """Role Schema for API representation."""

    class Meta:
        """Define fields which will be available."""

        fields = ('id', 'name')


class SystemSchema(ma.Schema):

    types = fields.Nested(SystemTypeSchema, many=True)
    scancategory = fields.Nested(ScanCategorySchema)
    network = fields.Nested(NetworkSchema)

    class Meta:
        fields = (
            'id',
            'name',
            'types',
            'network',
            'ip_address',
            'location',
            'scan_enabled',
            'ids_enabled',
        )


SYS = SystemSchema()
SYSs = SystemSchema(many=True)


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

    def __repr__(self):
        return f"BOX4s ({self.ip_address}) DNS:{self.dns.ip_address} Gateway:{self.gateway.ip_address}"


class BOX4securitySchema(ma.Schema):

    types = fields.Nested(SystemTypeSchema, many=True)
    scancategory = fields.Nested(ScanCategorySchema)
    network = fields.Nested(NetworkSchema)
    dns = fields.Nested(SystemSchema)
    gateway = fields.Nested(SystemSchema)

    class Meta:
        fields = (
            'id',
            'name',
            'types',
            'network',
            'ip_address',
            'location',
            'scan_enabled',
            'ids_enabled',
            'dns',
            'gateway',
        )


BOX4sSchema = BOX4securitySchema()


class NetworkForm(ModelForm, FlaskForm):
    """Form for Network model."""
    class Meta:
        model = Network
    types = SelectMultipleField(
        'Netz-Typ',
        coerce=int
    )
    scancategory_id = SelectField(
        'Scan-Kategorie',
        coerce=int
    )


class NetworkTypeForm(ModelForm, FlaskForm):
    """Form for NetworkType model."""
    class Meta:
        model = NetworkType


class SystemForm(ModelForm, FlaskForm):
    """Form for NetworkType model."""
    class Meta:
        model = System
    types = SelectMultipleField(
        'System-Typ',
        coerce=int
    )
    network_id = SelectField(
        'Netz',
        coerce=int
    )


class BOX4sForm(ModelForm, FlaskForm):
    """Form for BOX4s."""
    class Meta:
        model = BOX4security
    dns_id = SelectField(
        'DNS-Server',
        coerce=int
    )
    gateway_id = SelectField(
        'Gateway',
        coerce=int
    )
    network_id = SelectField(
        'Netz',
        coerce=int
    )


class SystemTypeForm(ModelForm, FlaskForm):
    """Form for SystemType model."""
    class Meta:
        model = SystemType


class BOX4securityForm(SystemForm):
    """Form for the BOX4security."""
