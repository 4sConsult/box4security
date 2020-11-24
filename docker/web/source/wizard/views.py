from flask import redirect, render_template, url_for, request, Blueprint
from .models import System, Network, SystemType, NetworkType, BOX4security, ScanCategory
from .forms import NetworkForm, SystemForm, BOX4sForm
from .middleware import WizardMiddleware
from source.extensions import db
from sqlalchemy.exc import SQLAlchemyError
from flask.helpers import flash

import tempfile
import shutil
import os
import re

bpWizard = Blueprint('wizard', __name__, template_folder='templates')


@bpWizard.before_request
def check_if_wizard():
    if not WizardMiddleware.isShowWizard():
        return redirect(url_for('index'))


@bpWizard.route('/', methods=['GET', 'POST'])
def index():
    return render_template('wizard/index.html')


@bpWizard.route('/networks', methods=['GET', 'POST'])
def networks():
    formNetwork = NetworkForm(request.form)
    formNetwork.types.choices = [(t.id, t.name) for t in NetworkType.query.order_by('id')]
    formNetwork.scancategory_id.choices = [(c.id, c.name) for c in ScanCategory.query.order_by('id')]
    if request.method == 'POST':
        if formNetwork.validate():
            newNetwork = Network()
            formNetwork.populate_obj(newNetwork)  # Copies matching attributes from form onto newNetwork
            if newNetwork.types:
                newNetwork.types = [NetworkType.query.get(tid) for tid in newNetwork.types]  # Get actual type objects from their IDs
            db.session.add(newNetwork)
            db.session.commit()
            return redirect(url_for('wizard.networks'))
    networks = Network.query.order_by(Network.id.asc()).all()
    scan_categories = ScanCategory.query.order_by(ScanCategory.id.asc()).all()
    return render_template('wizard/networks.html', formNetwork=formNetwork, networks=networks, scan_categories=scan_categories)


@bpWizard.route('/box4s', methods=['GET', 'POST'])
def box4s():
    formBOX4s = BOX4sForm(request.form)
    formBOX4s.network_id.choices = [(n.id, f"{n.name} ({n.ip_address}/{n.cidr})") for n in Network.query.order_by('id')]
    formBOX4s.dns_id.choices = [(s.id, f"{s.name} ({s.ip_address})") for s in System.query.order_by('id').filter(System.types.any(name='DNS-Server'))]
    formBOX4s.dns_id.choices += [(-1, "Andere..")]
    formBOX4s.gateway_id.choices = [(s.id, f"{s.name} ({s.ip_address})") for s in System.query.order_by('id').filter(System.types.any(name='Gateway'))]
    formBOX4s.gateway_id.choices += [(-1, "Andere..")]
    systemTypes = SystemType.query.filter(SystemType.name != 'BOX4security').order_by(SystemType.id.asc()).all()
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
    return render_template('wizard/box4s.html', formBOX4s=formBOX4s, box4s=BOX4s, systemTypes=systemTypes)


@bpWizard.route('/systems', methods=['GET', 'POST'])
def systems():
    formSystem = SystemForm(request.form)
    formSystem.network_id.choices = [(n.id, f"{n.name} ({n.ip_address}/{n.cidr})") for n in Network.query.order_by('id')]
    formSystem.types.choices = [(t.id, t.name) for t in SystemType.query.order_by('id').filter(SystemType.name != 'BOX4security')]
    if request.method == 'POST':
        if formSystem.validate():
            newSystem = System()
            formSystem.populate_obj(newSystem)  # Copies matching attributes from form onto newSystem
            if newSystem.types:
                newSystem.types = [SystemType.query.get(tid) for tid in newSystem.types]  # Get actual type objects from their IDs
            db.session.add(newSystem)
            db.session.commit()
            return redirect(url_for('wizard.systems'))
    systems = System.query.order_by(System.id.asc()).all()
    return render_template('wizard/systems.html', formSystem=formSystem, systems=systems)


@bpWizard.route('/mail', methods=['GET', 'POST'])
def smtp():
    return render_template('wizard/mail.html')


@bpWizard.route('/verify', methods=['GET', 'POST'])
def verify():
    if request.method == 'POST':
        apply()
        return render_template('wizard/verify_progress.html')
    networks = Network.query.order_by(Network.id.asc()).all()
    systems = System.query.order_by(System.id.asc()).all()
    BOX4s = BOX4security.query.order_by(BOX4security.id.asc()).first()
    scan_categories = ScanCategory.query.order_by(ScanCategory.id.asc()).all()
    return render_template('wizard/verify.html', networks=networks, systems=systems, box4s=BOX4s, scan_categories=scan_categories)


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

    # Step 7: Set the completed state.
    WizardMiddleware.setCompleted()
