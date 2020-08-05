#!/usr/bin/python3
"""Fetches and returns all versions greater than installed one."""
import requests
import semver
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
API_VER = requests.get('http://localhost/api/ver/', verify=False).json()
CURRVER = str(API_VER['version'])
ENV = str(API_VER['env'])
tags = requests.get('http://localhost/api/ver/releases/', verify=False).json()
VERSIONS = []
# Source: https://stackoverflow.com/questions/11887762/how-do-i-compare-version-numbers-in-python
for t in tags:
    # now compare the versions
    # discard all lower and equal versions
    if semver.compare(CURRVER, str(t['version'])) < 0:
        # semver.compare returns -1 if second argument is newer
        if not semver.parse(t['version'])['prerelease']:
            # Hide prereleases from VERSIONS
            VERSIONS.append(t['version'])

# For development systems:
if ENV == "dev":
    # add the latest tag if it is not in VERSIONS yet
    # so it is a prerelease actually
    latest = tags[0]['version']
    if latest not in VERSIONS:
        VERSIONS.insert(0, latest)

# !! Script Output!!
# All Versions greater than installed one
# Latest Release last
for t in reversed(VERSIONS):
    print(t)
