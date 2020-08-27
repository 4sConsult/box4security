import json
from datetime import datetime

# Setup variables for calculation.
# Each is dictionary, accessed by the keys gotten from Elasticsearch query. Refer to the query json.

# Weight of vulnerability severity.
WEIGHT = {
    'critical': 15,
    'high': 5,
    'medium': 1,
    'low': 0.1
}

# Threshold of vulnerability severity.
# Define here above which state the severity category flags as 0.
# E.g. multiply num of vulnerabilities by their weight until THRESHOLD, then just set 0.
THRESHOLD = {
    'critical': 5,
    'high': 10,
    'medium': 50,
    'low': 500
}

# List of rules
# Hold a dictionary which must have a `text` member for displaying measures to increase score.
RULES = {
    'critical': {'text': 'Im Netzwerk existiert mindestens eine kritische Schwachstelle.'},
    'high': {'text': 'Im Netzwerk existiert mindestens eine Schwachstelle mit hoher Schwere.'},
    'medium': {'text': 'Im Netzwerk existiert mindestens eine mittlere Schwachstelle.'},
    'low': {'text': 'Im Netzwerk existiert mindestens eine geringe Schwachstelle.'},
}

# Calculate the total weight by summing up the dictionary.
totalWeight = sum(WEIGHT.values())
# Initialize score as 0
vulnscore = 0.0
# List of offended rules from RULES.
offendingRules = []

# Read the contents of the result from Elasticsearch API query
file = open("/home/amadmin/box4s/scripts/Automation/score_calculation/vuln_score_result.json", "r")
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
    numUnique = bucket['doc_count'] - bucket['cvssUniqueVul']['sum_other_doc_count']  # calculate the number of unique vulnerabilities
    if numUnique:
        offendingRules.append(RULES[severity])  # RULE offended, add it.
    if numUnique < THRESHOLD[severity]:  # Threshold not exceeded
        temp = numUnique / THRESHOLD[severity]  # Calulate fraction of threshold that was exceeded.
    else:
        temp = 1  # Threshold exceeded => must take whole weight into account.
    temp *= WEIGHT[severity]  # multiply the fraction by weight e.g. weighted arithmetic mean, step 1
    vulnscore += temp  # add the product to the vulnscore e.g. weighted arithmetic mean, step 2

vulnscore = vulnscore / totalWeight  # weighted arithmetic mean, step 3
vulnscore = 1 - vulnscore  # turn the percentage of not fulfilled into fulfilled 100%-X
vulnscore = round(vulnscore, 4)  # 0.0047234234 => 0.0047 (so 0.47%)


result = {
    "score_type": "vuln_score",
    "value": vulnscore,
    "timestamp": int(datetime.now().timestamp()),
    "rules": offendingRules
}

with open('/tmp/vuln.scores.json', 'w') as tmpVuln:
    json.dump(result, tmpVuln)

print(result)
exit(0)
