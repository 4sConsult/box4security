# Developed for Python 3.5.2 (Version of QC Image)
import argparse
import urllib.request
import json
import os
import tempfile
import re
import shutil
import csv
import ipaddress
from collections import defaultdict

logstash_path = "/etc/logstash/conf.d/"

# if you get an request error, do pip install --user requests
import requests

# Parser Stuff
parser = argparse.ArgumentParser()
parser.add_argument('--host',dest="host",default="it-security.am-gmbh.de",help="Supply a host to use for the API, useful for local testing, e.g.: --host localhost/its-plattform")
parser.add_argument('--quickcheck','-q',dest='quickcheck',help="Quickcheck ID to be used",metavar="QUICKCHECK_ID")
parser.add_argument('-u', '--user',dest='api_user', help="Specify the username to use the API as", metavar="USERNAME")
parser.add_argument('-p','--pass',dest='api_pass', help="Specify the valid api token for the username. WARNING: Specifying the token via CMDLINE is not recommended for security reasons.", metavar="TOKEN")
parser.add_argument('-i', dest='ignore_cert', help="Ignore certificate validation errors", action="store_const", default=False, const=True)
args = parser.parse_args()

if os.geteuid() != 0:
    print("Script needs to be run as root.")
    exit(2)

# Drop privileges for downloading
if os.geteuid() == 0:
    os.seteuid(1000)
print("Dropping privileges for downloading")
if args.api_user is None:
    api_user = input("Please enter your username (ITS-Plattform): ")
else:
    api_user = args.api_user

if args.api_pass is None:
    print('API Token not specified via -p API_TOKEN.')
    print('Get your token from https://{}/users/settings/'.format(args.host))
    api_pass = input("Please enter the API-Token for {}: ".format(api_user))
else:
    api_pass = args.api_pass

url = 'http://'+args.host + '/api/'
# follows server redirects to https
headers = {'X-AM-API_USER': api_user, 'X-AM-API_TOKEN': api_pass}

print("Will use {} as api host.".format(url))

if args.quickcheck is None:
    quickcheck = input("Please enter the quickcheck_id: ")
else:
    quickcheck = args.quickcheck

ignore_cert = args.ignore_cert
print("Fetching Networks")
resp = requests.get(url=url+"quickchecks/{}/networks".format(quickcheck), headers=headers, verify=(not ignore_cert))
if resp.status_code is requests.codes.ok:
    networks = resp.json()['response']
else:
    resp.raise_for_status()
    exit()

nets = resp.json()['response']
print("Received Networks")
for net in nets:
    print("\t{}/{} : {} {}".format(net['ip'],net['cidr'],net['type'],'('+net['purpose']+')' if net['purpose'] is not '' else ''))

print("Fetching Systems")
resp = requests.get(url=url+"quickchecks/{}/systems".format(quickcheck), headers=headers, verify=(not ignore_cert))
if resp.status_code is requests.codes.ok:
    systems = resp.json()['response']
else:
    resp.raise_for_status()
    exit()

print("Received Systems")
qc = None
gw = None
dns = []
for sys in systems:
    print("\t{ip}: {types}, NOSCAN: {noscan}, NOTRACK: {notrack} ,{purpose}".format(ip=sys['ip'], types=sys['types'], noscan=sys['noscan'], notrack=sys['notrack'], purpose=('('+sys['purpose']+')' if sys['purpose'] is not '' else '')))
    if 'Quickcheck-System' in sys['types']:
        qc = sys
    if 'DNS-Server' in sys['types']:
        dns.append(sys)
    if 'Gateway' in sys['types']:
        gw = sys

if networks:
    print("Exporting Networks")
    with open('/home/amadmin/{qc}-networks.csv'.format(qc=quickcheck),'w', newline='') as fd_netcsv:
        csvwriter = csv.DictWriter(fd_netcsv,delimiter=';', fieldnames=networks[0].keys())
        csvwriter.writeheader()
        csvwriter.writerows(networks)
    print("Exported Networks to "+'/home/amadmin/{qc}-networks.csv'.format(qc=quickcheck))

if systems:
    print("Exporting Systems")
    with open('/home/amadmin/{qc}-systems.csv'.format(qc=quickcheck),'w', newline='') as fd_syscsv:
        csvwriter = csv.DictWriter(fd_syscsv,delimiter=';', fieldnames=systems[0].keys())
        csvwriter.writeheader()
        for sys in systems:
            for type in sys['types']:
                _sys = sys.copy()
                _sys['types'] = type
                csvwriter.writerow(_sys)
    print("Exported Systems to "+'/home/amadmin/{qc}-systems.csv'.format(qc=quickcheck))



# time to escalate back to root
print("Raising privileges again.")
os.seteuid(0)

# local ip regex for /etc/network/interfaces
exp = re.compile(r"(^\s*address )((10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(172\.1[6-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.3[0-1]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}))\s*$")

# local gw regex for /etc/network/interfaces
expgw = re.compile(r"(^\s*gateway )((10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(172\.1[6-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.3[0-1]\.[0-9]{1,3}\.[0-9]{1,3})|(172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3})|(192\.168\.[0-9]{1,3}\.[0-9]{1,3}))\s*$")


if qc is not None:
    # read network interfaces
    print("Setting Quickcheck IP to {}".format(qc['ip']))
    new, new_path = tempfile.mkstemp(text=True)
    with open('/etc/network/interfaces','r') as fd_interfaces:
        with open(new, 'w') as new_f:
          for line in fd_interfaces:
              line = exp.sub(r"\g<1>{}\n".format(qc['ip']),line)
              new_f.write(line)
          new_f.seek(0)
          shutil.copy(new_path,'/etc/network/interfaces')
    os.remove(new_path)
    fd_interfaces.close()
    print("Quickcheck IP set in /etc/network/interfaces.")


if gw is not None:
    # read network interfaces
    print("Setting Quickcheck Gateway to {}".format(gw['ip']))
    new, new_path2 = tempfile.mkstemp(text=True)
    with open('/etc/network/interfaces','r') as fd2_interfaces:
        with open(new, 'w') as new_f2:
          for line2 in fd2_interfaces:
              line2 = expgw.sub(r"\g<1>{}\n".format(gw['ip']),line2)
              new_f2.write(line2)
          new_f2.seek(0)
          shutil.copy(new_path2,'/etc/network/interfaces')
    os.remove(new_path2)
    fd2_interfaces.close()
    print("Gateway set in /etc/network/interfaces.")

if dns is not None:
    dnscontent = ""
    for srv in dns:
        dnscontent += "nameserver {}\n".format(srv['ip'])
    with open('/etc/resolv.personal', 'w') as fd3_interfaces:
        fd3_interfaces.write(dnscontent)
    fd3_interfaces.close()
    print("DNS set in /etc/resolv.personal")


# Logstash options
print("Setting Openvas Data Enrichment")
nettemplate = """
        cidr {{
            address => [ "%{{[client][ip]}}" ]
            network => [ "{network}/{cidr}" ]
            add_field => {{"[network][name]" => "{type}" }}
            add_field => {{"[network][description]" => "{desc}" }}
        }}
            """
systemplate = """
        if [client][ip] in [{iplist}]
        {{
            mutate {{
                add_field => {{"[host][type]" => "{type}" }}
            }}
        }}
            """
subtypetemplate = """
        if [client][ip] == "{ip}"
        {{
            mutate {{
                add_field => {{ "[host][subtype]" => {subt_json} }}
            }}
        }}
            """
content = ""
with open(logstash_path+'/openvas/20_openvas_filter.conf','r') as fd_openvas:
    fd_openvas.seek(0)
    content = fd_openvas.read()

replace = ""
for net in nets:
    replace += nettemplate.format(network=net['ip'],cidr=net['cidr'], type=net['type'], desc=net['purpose']) + "\n"
content = re.sub(r"# {! PLACEHOLDER CIDR !}",replace,content)

byips = defaultdict(list)
for sys in systems:
    for ty in sys['types']:
        if ty not in ['Server', 'Client', 'Misc', 'Netzwerkinfrastruktur']:
            byips[sys['ip']].append(ty)

replace = ""
for o in byips:
    jsnobj = json.dumps(byips[o], ensure_ascii=False)
    replace += subtypetemplate.format(ip=o, subt_json=jsnobj.replace('\'', ''))
bytypes = defaultdict(list)
for sys in systems:
    for ty in sys['types']:
        if ty in ['Server', 'Client', 'Netzwerkinfrastruktur']:
            bytypes[ty].append(sys)
            break
        elif ty is sys['types'][-1]:
            bytypes['Misc'].append(sys)
for type in bytypes:
    iplist = ""
    for sys in bytypes[type]:
        iplist += '"{}",'.format(sys['ip'])
    iplist = iplist[:-1]
    # workround to have minimum two ips in list (because I read logstash has bugs if just 1 element in list)
    if len(bytypes[type]) == 1:
        iplist += ", "+iplist
    replace += systemplate.format(iplist=iplist,type=type)
content = re.sub(r"# {! PLACEHOLDER IP !}",replace,content)


with open(logstash_path +'/openvas/20_openvas_filter.conf','w',encoding='utf-8') as fd_openvas:
    fd_openvas.write(content)

print("Openvas Data Enrichment set")

print("Setting Suricata Data Enrichment")

content = ""
with open(logstash_path+'/general/AM-special.conf','r') as fd_suricata:
    fd_suricata.seek(0)
    content = fd_suricata.read()

replace = ""
for net in nets:
    replace += nettemplate.format(network=net['ip'],cidr=net['cidr'], type=net['type'], desc=net['purpose']) + "\n"
content = re.sub(r"# {! PLACEHOLDER CIDR !}",replace,content)

droplist = ""

for sys in systems:
    if sys['notrack']:
        droplist += '"{}",'.format(sys['ip'])
for ip in ["127.0.0.1", "127.0.0.53", "localhost"]:
    droplist += '"{}",'.format(ip)
# removes trailing comma:
droplist = droplist[:-1]


droptemplate="""
        if [client][ip] in [{iplist}]
        {{
            drop {{ }}
        }}
            """
content = re.sub(r"# {! PLACEHOLDER DROP !}", droptemplate.format(iplist=droplist) ,content)

replace = ""
for o in byips:
    jsnobj = json.dumps(byips[o], ensure_ascii=False)
    replace += subtypetemplate.format(ip=o,subt_json=jsnobj)
for type in bytypes:
    iplist = ""
    for sys in bytypes[type]:
        iplist += '"{}",'.format(sys['ip'])
    iplist = iplist[:-1]
    if len(bytypes[type]) == 1:
        iplist += ", "+iplist
    replace += systemplate.format(iplist=iplist,type=type)

content = re.sub(r"# {! PLACEHOLDER IP !}",replace,content)


with open(logstash_path+ '/general/AM-special.conf','w',encoding='utf-8') as fd_suricata:
    fd_suricata.write(content)

print("Suricata Data Enrichment set")
print("Editing nmap scan.sh")
print("Dropping privileges for edit")
os.seteuid(1000)

scan_sh = """#!/bin/bash
nmap -sP {networks} {excludes} -oX - | curl --silent --header "x-nmap-target: {networks}" --header "-nmap-type: listscan"  http://localhost:5045 --data-binary @- 2>&1
"""
noscan_ips = []
nmap_networks = ' '.join(net['ip']+'/'+str(net['cidr']) for net in networks)
nmap_excl = ','.join(sys['ip'] for sys in systems if sys['noscan'])
if nmap_excl != '':
    nmap_excl = '--exclude ' + nmap_excl

with open(os.environ["BASEDIR"]+os.environ["GITDIR"] + '../listscan.sh','w') as fd_scansh:
    fd_scansh.write(scan_sh.format(networks=nmap_networks, excludes=nmap_excl))


os.system('chmod +x "'+os.environ["BASEDIR"]+os.environ["GITDIR"]+'""../listscan.sh"')
print("nmap job listscan.sh edited")



scan_sh = """#!/bin/bash
nmap -A {networks} {excludes} -oX - | curl --silent --header "x-nmap-target: {networks}" --header "x-nmap-type: fullscan" http://localhost:5045 --data-binary @- 2>&1
"""
noscan_ips = []
nmap_networks = ' '.join(net['ip']+'/'+str(net['cidr']) for net in networks)
nmap_excl = ','.join(sys['ip'] for sys in systems if sys['noscan'])
if nmap_excl != '':
    nmap_excl = '--exclude ' + nmap_excl

with open(os.environ["BASEDIR"]+os.environ["GITDIR"] + '../fullscan.sh','w') as fd_scansh:
        fd_scansh.write(scan_sh.format(networks=nmap_networks, excludes=nmap_excl))
os.system('chmod +x "'+os.environ["BASEDIR"]+os.environ["GITDIR"]+'""../fullscan.sh"')
print("nmap job fullscan.sh edited")



scan_sh = """#!/bin/bash
nmap --traceroute -sP {networks} {excludes} -oX - | curl --silent --header "x-nmap-target: {networks}" --header "x-nmap-type: traceroute" http://localhost:5045 --data-binary @- 2>&1
"""
noscan_ips = []
nmap_networks = ' '.join(net['ip']+'/'+str(net['cidr']) for net in networks)
nmap_excl = ','.join(sys['ip'] for sys in systems if sys['noscan'])
if nmap_excl != '':
    nmap_excl = '--exclude ' + nmap_excl

with open(os.environ["BASEDIR"]+os.environ["GITDIR"] + '../tracescan.sh','w') as fd_scansh:
    fd_scansh.write(scan_sh.format(networks=nmap_networks, excludes=nmap_excl))
os.system('chmod +x "'+os.environ["BASEDIR"]+os.environ["GITDIR"]+'""../tracescan.sh"')
print("nmap job tracescan.sh edited")


# Setup Heartbeat monitors
heartbeat_template = """- type: icmp
  schedule: '@every {period}s'
  hosts: {hostlist}
  """
# time to escalate back to root
os.seteuid(0)
with open('/etc/heartbeat/monitors.d/kunde.yml', 'w') as fd_monitor:
    for net in nets:
        fd_monitor.write(heartbeat_template.format(period=10, hostlist=[str(ip) for ip in ipaddress.IPv4Network(address="{}/{}".format(net['ip'], net['cidr']))]))
print('Hearbeat Monitors set up')

new, new_path = tempfile.mkstemp(text=True)
envst = os.stat('/etc/environment')
with open('/etc/environment', 'r') as fd_env:
    with open(new, 'w') as new_f:
        for line in fd_env:
            if "KUNDE=" in line:
                line = "KUNDE={}\n".format(str(quickcheck_id))
            new_f.write(line)
        new_f.seek(0)
    shutil.copy(new_path, '/etc/environment')
os.remove(new_path)
fd_env.close()
os.chown('/etc/environment', envst[stat.ST_UID], envst[stat.ST_GID])
print('/etc/environment edited. You need to reboot or export the variables in /etc/environment to apply!')
