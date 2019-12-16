from . import models, db, auth, helper
import re
import os
import socket
import tempfile
import shutil
import stat
from string import Template


def run():
    networks, systems = fetchFromDB()
    auth.raise_privileges()
    modInterface(networks, systems)
    modDNS(networks, systems)
    modEnvironment(networks, systems)
    modGeneral(networks, systems)
    modSuricata(networks, systems)
    modGSA()
    modHosts(networks, systems)


def fetchFromDB():
    networks = db.session.query(models.Network)
    systems = db.session.query(models.System)
    return networks, systems


def inputIP():
    while True:
        candidate = input()
        try:
            socket.inet_aton(candidate)
        except socket.error:
            print("Entered IP invalid. Please retry:")
        else:
            return candidate


def modGSA():
    allowheaderhostpattern = r'(--allow-header-host \s*)((10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(172\.1[6-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.3[0-1]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}))'
    box = db.session.query(models.System).join(models.SystemType, models.System.types).filter(models.SystemType.name == 'BOX4security').first()
    with open('/etc/systemd/system/multi-user.target.wants/greenbone-security-assistant.service', 'r') as fd_gsa:
        content = fd_gsa.read()
        content = re.sub(allowheaderhostpattern, r'\g<1>{}'.format(box.ip), content)
    with open('/etc/systemd/system/multi-user.target.wants/greenbone-security-assistant.service', 'w') as fd_gsa:
        fd_gsa.write(content)
    print("Set IP as Greenbone Security Assistant Host Header.")


def modInterface(networks, systems):
    joined = db.session.query(models.System).join(models.SystemType, models.System.types)
    box = joined.filter(models.SystemType.name == 'BOX4security').first()
    gateway = joined.filter(models.SystemType.name == 'Gateway').first()

    if not box:
        box = models.System()
        boxtype = db.session.query(models.SystemType).filter(models.SystemType.name == 'BOX4security').first()
        if not boxtype:
            boxtype = models.SystemType(name='BOX4security')
            db.session.add(boxtype)
        box.types = [boxtype]
        print("No BOX4security IP set. Enter one now:")
        box.ip = inputIP()
        db.session.add(box)
        db.session.commit()

    if not gateway:
        gateway = models.System()
        gatewaytype = db.session.query(models.SystemType).filter(models.SystemType.name == 'Gateway').first()
        if not gatewaytype:
            gatewaytype = models.SystemType(name='Gateway')
            db.session.add(gatewaytype)
        gateway.types = [gatewaytype]
        print("No Gateway for BOX4security set. Enter one now:")
        gateway.ip = inputIP()
        db.session.add(gateway)
        db.session.commit()

    print('Setting IP in Network Interfaces to {ip}'.format(ip=box.ip))
    print('Setting Gateway in Network Interfaces to {ip}'.format(ip=gateway.ip))
    # local ip and gateway regex for /etc/network/interfaces
    addrexp = re.compile(r"(^\s*address )((10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(172\.1[6-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.3[0-1]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}))\s*$")
    gwexp = re.compile(r"(^\s*gateway )((10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(172\.1[6-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.3[0-1]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}))\s*$")
    tmp, tmp_path = tempfile.mkstemp(suffix="BOX4s", text=True)
    with open('/etc/network/interfaces', 'r') as fd_interfaces:
        with open(tmp, 'w') as fd_tmp:
            for line in fd_interfaces:
                line = addrexp.sub(r"\g<1>{}\n".format(box.ip), line)
                line = gwexp.sub(r"\g<1>{}\n".format(gateway.ip), line)
                fd_tmp.write(line)
            fd_tmp.seek(0)
            shutil.copy(tmp_path, '/etc/network/interfaces')
        os.remove(tmp_path)
    fd_interfaces.close()
    print('Network Interfaces edited.')


def modDNS(networks, systems):
    joined = systems.join(models.SystemType, models.System.types)
    dnsservers = joined.filter(models.SystemType.name == 'DNS-Server').all()
    if not dnsservers:
        dnsservers = []
        print("No DNS Servers set in DB. Would you like to set some? Type 'y' for yes.")
        if helper.userConfirm():
            dnstype = db.session.query(models.SystemType).filter(models.SystemType.name == 'DNS-Server').first()
            if not dnstype:
                dnstype = models.SystemType(name='DNS-Server')
                db.session.add(dnstype)
            while True:
                dns = models.System()
                print("Enter IP for DNS:")
                dns.ip = inputIP()
                dns.types = [dnstype]
                dnsservers.append(dns)
                db.session.add(dns)
                print("Would you like to add another DNS Server? Type 'y' for yes.")
                if not helper.userConfirm():
                    break
            db.session.commit()
    # Even with no DNS servers from DB and no DNS Servers entered,
    # the resolv.personal should be reset to empty file!!!!!
    with open('/etc/resolv.personal', 'w') as fd_resolv:
        for dns in dnsservers:
            fd_resolv.write('nameserver {ip}\n'.format(ip=dns.ip))
    fd_resolv.close()
    print("DNS set in /etc/resolv.personal")


def modEnvironment(networks, systems):
    box = db.session.query(models.System).join(models.SystemType, models.System.types).filter(models.SystemType.name == 'BOX4security').first()
    branches = db.session.query(models.Branch).all()
    for branch in branches:
        if branch:
            print(branch)
    branch = None
    while not branch:
        print("Please select the branch you want to apply here: (type number)")
        no = input()
        branch = db.session.query(models.Branch).filter(models.Branch.id == no).first()
    tmp, tmp_path = tempfile.mkstemp(text=True)
    statEnv = os.stat('/etc/environment')
    with open('/etc/environment', 'r') as fd_env:
        with open(tmp, 'w') as fd_tmp:
            for line in fd_env:
                if "KUNDE=" in line:
                    line = "KUNDE={kunde}\n".format(kunde=''.join(branch.name.split()) if branch.name else branch.bicompanyid)
                elif "INT_IP=" in line:
                    line = "INT_IP={ip}\n".format(ip=box.ip)
                fd_tmp.write(line)
            fd_tmp.seek(0)
        shutil.copy(tmp_path, '/etc/environment')
    os.remove(tmp_path)
    fd_env.close()
    os.chown('/etc/environment', statEnv[stat.ST_UID], statEnv[stat.ST_GID])
    print('/etc/environment edited. Reboot or restart of applications might be required!')


def modGeneral(networks, systems):
    drop_systems_iplist = [ip for ip, in db.session.query(models.System.ip).filter(models.System.notrack).all()]
    drop_systems_iplist += ['localhost', '127.0.0.1', '127.0.0.53']
    if os.getenv('INT_IP'):
        drop_systems_iplist += os.getenv('INT_IP')
    with open('/etc/logstash/conf.d/general/BOX4s-special.conf', 'r') as fd_4sspecial:
        fd_4sspecial.seek(0)
        content = fd_4sspecial.read()

        fd_nettemplate = open('fetchqc/templates/network.template', 'r')
        templateNetwork = Template(fd_nettemplate.read())
        fd_nettemplate.close()

        fd_typestemplate = open('fetchqc/templates/type.template', 'r')
        templateType = Template(fd_typestemplate.read())
        fd_typestemplate.close()

        fd_droptemplate = open('fetchqc/templates/drop.template', 'r')
        templateDrop = Template(fd_droptemplate.read())
        fd_droptemplate.close()

        replaceCIDR = ""
        for net in networks.all():
            replaceCIDR += templateNetwork.substitute(network=net.ip, cidr=net.cidr, type=net.type, desc=net.purpose)
        content = re.sub(r"# {! PLACEHOLDER CIDR !}", replaceCIDR, content)

        replaceDROP = templateDrop.substitute(iplist=drop_systems_iplist)
        content = re.sub(r"# {! PLACEHOLDER DROP !}", replaceDROP, content)

        replaceIP = ""
        all_types = db.session.query(models.SystemType).all()
        for type in all_types:
            iplist = []
            for sys in systems.join(models.SystemType, models.System.types).filter(models.SystemType.id == type.id).all():
                if not sys.notrack:
                    iplist.append(sys.ip)
            if iplist:
                replaceIP += templateType.substitute(iplist=iplist, type=type)

        content = re.sub(r"# {! PLACEHOLDER IP !}", replaceIP, content)
    with open('/etc/logstash/conf.d/general/BOX4s-special.conf', 'w', encoding='utf-8') as fd_4sspecial:
        fd_4sspecial.write(content)
    print("Changes written to BOX4s-special.conf")


def modSuricata(networks, systems):
    box = db.session.query(models.System).join(models.SystemType, models.System.types).filter(models.SystemType.name == 'BOX4security').first()
    with open('/etc/suricata/suricata.yaml', 'r', encoding='utf-8') as fd_suricata:
        content = fd_suricata.read()
        content = re.sub(r"(\s*INTERNAL_IP: )", r'\g<1>["{}"]\n'.format(box.ip), content)
    with open('/etc/suricata/suricata.yaml', 'w', encoding='utf-8') as fd_suricata:
        fd_suricata.write(content)
    print("Changes written to suricata.yaml")


def modHosts(networks, systems):
    box = db.session.query(models.System).join(models.SystemType, models.System.types).filter(models.SystemType.name == 'BOX4security').first()
    with open('/etc/hosts', 'r', encoding='utf-8') as fd_hosts:
        content = fd_hosts.read()
        content = re.sub(r"(.*[0-9])(\s*box4security\.ip)", r'{}\g<2>\n'.format(box.ip), content)
    with open('/etc/hosts', 'w', encoding='utf-8') as fd_hosts:
        fd_hosts.write(content)
    print('IP written to /etc/hosts.')


def modLogstashDefault(networks, systems):
    box = db.session.query(models.System).join(models.SystemType, models.System.types).filter(models.SystemType.name == 'BOX4security').first()
    with open('/etc/default/logstash', 'r', encoding='utf-8') as fd_deflogstash:
        content = fd_deflogstash.read()
        content = re.sub(r'(INT_IP=")([0-9\.]+)(")', r'\g<1>{}\g<3>'.format(box.ip), content)
    with open('/etc/default/logstash', 'r', encoding='utf-8') as fd_deflogstash:
        fd_deflogstash.write(content)
    print('INT_IP written to /etc/default/logstash')
