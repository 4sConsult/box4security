import json
from datetime import datetime

# Setup variables for calculation.
# Each is dictionary, accessed by the keys gotten from Elasticsearch query. Refer to the query json.

# Weight of vulnerability severity.
WEIGHT = {
    'critical': 15,
    'high': 5,
    'medium': 1,
    'low': 0.1,
    'disabled': 2,
}

# Threshold of vulnerability severity.
# Define here above which state the severity category flags as 0.
# E.g. multiply num of vulnerabilities by their weight until THRESHOLD, then just set 0.
THRESHOLD = {
    'critical': 10,
    'high': 50,
    'medium': 100,
    'low': 500,
    'disabled': 0,
}

# List of rules
# Hold a dictionary which must have a `text` member for displaying measures to increase score.
RULES = {
    'critical': {'text': 'Im Netzwerk existiert mindestens eine kritische Schwachstelle.'},
    'high': {'text': 'Im Netzwerk existiert mindestens eine Schwachstelle mit hoher Schwere.'},
    'medium': {'text': 'Im Netzwerk existiert mindestens eine mittlere Schwachstelle.'},
    'low': {'text': 'Im Netzwerk existiert mindestens eine geringe Schwachstelle.'},
    'disabled': {'text': 'Es werden keine Schwachstellenscans durchgeführt.'},
}

# Calculate the total weight by summing up the dictionary.
totalWeight = sum(WEIGHT.values())
# Initialize score as 0
vulnscore = 0.0
# List of offended rules from RULES.
offendingRules = []

# Boolean variable to identify if scans were even made => used to validate the rule of actually performing vulnerability scans.
scansEnabled = False

# Read the contents of the result from Elasticsearch API query
file = open("/core4s/scripts/Automation/score_calculation/cvss_buckets.json", "r")
# Load content into a json datastore
datastore = json.load(file)

# the information is under this key. It is a list of buckets by cvss range
# 0-2.5, 2.5-5, 5-7.5, 7.5-
# as defined in the query json.
# the right value is not included, the left is.
cvssbuckets = datastore['aggregations']['cvss']['buckets']

# for each severity bucket
for bucket in cvssbuckets:
    severity = bucket['key']  # find out exactly which bucket we are looking at
    try:
        numUnique = bucket['cvssUniqueVul']['value']  # assign the number of unique vulnerabilities / cardinality
    except KeyError:  # catch no vulns
        numUnique = 0
    if numUnique:
        scansEnabled = True
        offendingRules.append(RULES[severity])  # RULE offended, add it.
    if numUnique < THRESHOLD[severity]:  # Threshold not exceeded
        temp = numUnique / THRESHOLD[severity]  # Calulate fraction of threshold that was exceeded.
    else:
        temp = 1  # Threshold exceeded => must take whole weight into account.
    temp *= WEIGHT[severity]  # multiply the fraction by weight e.g. weighted arithmetic mean, step 1
    vulnscore += temp  # add the product to the vulnscore e.g. weighted arithmetic mean, step 2

# Rule: Vulnerability Scans must be performed, else: Penalty of WEIGHT['disabled']
if not scansEnabled:
    temp = 1  # Actually include the penalty. Can only be 0,1. In case of 0 => no effect, so left out here.
    temp *= WEIGHT['disabled']  # Multiply by weight
    vulnscore += temp  # add the product to the vulnscore e.g. weighted arithmetic mean, step 2
    offendingRules.append(RULES['disabled'])  # Vulnerabilty scans must be performed rule offended, add it.

vulnscore = vulnscore / totalWeight  # weighted arithmetic mean, step 3
vulnscore = 1 - vulnscore  # turn the percentage of not fulfilled into fulfilled 100%-X
vulnscore = round(vulnscore * 100, 2)  # 0.0047234234 => 0.0047 => 0.47%


result = {
    "score_type": "vuln_score",
    "value": vulnscore,
    "timestamp": int(datetime.utcnow().timestamp()) * 1000,
    "rules": offendingRules
}

with open('/tmp/vuln.scores.json', 'w') as tmpVuln:
    json.dump(result, tmpVuln)

print(result['value'])
