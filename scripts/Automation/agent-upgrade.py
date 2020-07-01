import json
import requests
import os

# TODO: Updatescript for wazuh agents
# https://documentation.wazuh.com/3.12/user-manual/agents/remote-upgrading/upgrading-agent.html
url = "http://wazuh:55000/agents/outdated?pretty"
headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}
r = requests.get(url, headers=headers, auth=(os.getenv('WAZUH_USER'), os.getenv('WAZUH_PASS')))
r.json()
