#!/usr/bin/python3
import sys
import json
# 3rd party but used in setuptools so should be installed:
from packaging import version
# !!!! INPUT !!!!
# Script expects piped input of GitLab API /tags endpoint
# e.g.
# https://lockedbox-bugtracker.am-gmbh.de/api/v4/projects/AM-GmbH%2Fbox4s/repository/tags

# Source: https://stackoverflow.com/questions/11887762/how-do-i-compare-version-numbers-in-python
with open('/home/amadmin/VERSION') as f:
    # Readline and remove new line
    CURRVER = version.parse(f.read().splitlines()[0])
VERSIONS = []
for t in json.load(sys.stdin):
    # print(version.parse(t['name']))
    # now compare the versions
    # discard all lower and equal versions
    v = version.parse(t['name'])
    if v > CURRVER:
        VERSIONS.append(v)

# !! Script Output!!
# All Versions greater than installed one
# Latest Release last
for t in reversed(VERSIONS):
    print(t)
