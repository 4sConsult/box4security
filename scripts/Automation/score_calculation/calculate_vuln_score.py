import json
from datetime import datetime


WEIGHT = {
    'critical': 15,
    'high': 5,
    'medium': 1,
    'low': 0.1
}

THRESHOLD = {
    'critical': 5,
    'high': 10,
    'medium': 50,
    'low': 500
}

passed = {
    'critical': 0,
    'high': 0,
    'medium': 0,
    'low': 0,
}


offendingRules = []

RULES = {
    'critical': {'text': 'Im Netzwerk existiert mindestens eine kritische Schwachstelle.'},
    'high': {'text': 'Im Netzwerk existiert mindestens eine Schwachstelle mit hoher Schwere.'},
    'medium': {'text': 'Im Netzwerk existiert mindestens eine mittlere Schwachstelle.'},
    'low': {'text': 'Im Netzwerk existiert mindestens eine geringe Schwachstelle.'},
}

totalWeight = sum(WEIGHT.values())
vulnscore = 0.0

# Read the contents of the result
file = open("/home/amadmin/box4s/scripts/Automation/score_calculation/vuln_score_result.json", "r")
# Load content into a json datastore
datastore = json.load(file)

cvssbuckets = datastore['aggregations']['cvss']['buckets']


for bucket in cvssbuckets:
    severity = bucket['key']
    numUnique = bucket['doc_count'] - bucket['cvssUniqueVul']['sum_other_doc_count']
    if numUnique:
        offendingRules.append(RULES[severity])
    if numUnique < THRESHOLD[severity]:
        temp = numUnique / THRESHOLD[severity]
    else:
        temp = 1
    temp *= WEIGHT[severity]
    vulnscore += temp

vulnscore = vulnscore / totalWeight
vulnscore = 1 - vulnscore
vulnscore = round(vulnscore, 4)


result = {
    "score_type": "vuln_score",
    "value": vulnscore,
    "timestamp": int(datetime.now().timestamp()),
    "rules": offendingRules
}

print(result)
exit(0)