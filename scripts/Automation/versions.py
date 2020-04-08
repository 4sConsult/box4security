#!/usr/bin/python3
"""Fetches and returns all versions greater than installed one."""
import requests
import semver
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
CURRVER = requests.get('http://localhost/ver/', verify=False).json()['version']
tags = requests.get('http://localhost/ver/releases/', verify=False).json()
VERSIONS = []
# Source: https://stackoverflow.com/questions/11887762/how-do-i-compare-version-numbers-in-python
for t in tags:
    # now compare the versions
    # discard all lower and equal versions
    if semver.compare(CURRVER, t['version']) < 0:
        # semver.compare returns -1 if second argument is newer
        VERSIONS.append(t['version'])

# !! Script Output!!
# All Versions greater than installed one
# Latest Release last
for t in reversed(VERSIONS):
    print(t)
