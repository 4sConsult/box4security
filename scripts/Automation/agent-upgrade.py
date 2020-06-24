import json
import requests

# TODO: Updatescript for wazuh agents
# https://documentation.wazuh.com/3.12/user-manual/agents/remote-upgrading/upgrading-agent.html
url = "http://wazuh:55000/agents/outdated?pretty"
headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}
r = requests.get(url, headers=headers, auth=('box4s', 'wa3hz0hPW'))
r.json()
