import subprocess
import requests
from requests.exceptions import Timeout, ConnectionError


SERVICES = ['elasticsearch', 'logstash', 'kibana', 'suricata', 'filebeat', 'metricbeat', 'packetbeat']


def getServiceState(name):
    # Get and return service `name` state e.g. active/inactive
    try:
        p = subprocess.Popen(['systemctl', 'is-active', name], stdout=subprocess.PIPE)
    except OSError as e:
        return "(lookup failed)"
    (output, err) = p.communicate()
    return output.decode('utf-8')


def restartService(name):
    # Restart Service by name => return False in case of error, true else
    try:
        p = subprocess.Popen(['systemctl', 'restart', name], stdout=subprocess.PIPE)
    except OSError as e:
        return False
    return True


def changeServiceState(name, state):
    # Change service `name` to `state`, return True on success
    try:
        p = subprocess.Popen(['systemctl', state, name])
    except OSError as e:
        return False
    p.wait()
    # Wait until termination of systemctl command => May take some time!
    return True


def getLogstashPipes():
    # Query Logstash API for pipeline information, return list of pipeline names
    try:
        r = requests.get('http://localhost:9600/_node/pipelines')
    except ConnectionError as e:
        return ['error fetching pipeline information']
    except Timeout as e:
        return ['timeout fetching pipeline information']
    try:
        r = r.json()['pipelines'].keys()
    except ValueError as e:
        return ['error parsing api json response']
    return r
