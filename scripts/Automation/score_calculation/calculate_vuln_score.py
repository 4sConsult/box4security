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
    print(f'{severity}: {numUnique}')
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
    # "rules": offendingRules
}

print(result)
exit(0)


uniqueVuln = datastore['aggregations']['uniqueVul']['buckets']
offendingRules = []
RULES = {
    'criticalVuln': {'text': 'Im Netzwerk existiert mindestens eine kritische Schwachstelle.'},
    'highVuln': {'text': 'Im Netzwerk existiert mindestens eine Schwachstelle mit hoher Schwere.'},
    'mediumVuln': {'text': 'Im Netzwerk existiert mindestens eine mittlere Schwachstelle.'},
    'lowVuln': {'text': 'Im Netzwerk existiert mindestens eine geringe Schwachstelle.'},
}
for v in uniqueVuln:
    # e.g.: vData= {'@timestamp': '2020-07-30T10:54:44.010Z', 'uniqueVul': 'a9099e91203d147055c70a311ca33667', 'client': {'domain': '185.163.79.10'}, 'cvss': 8.5}
    vData = v['topUniqueVul']['hits']['hits'][0]['_source']
    try:
        if vData['cvss'] >= 7.5:
            vulnscore -= 0.25
            if RULES['criticalVuln'] not in offendingRules:
                offendingRules.append(RULES['criticalVuln'])
        elif 5 <= vData['cvss'] < 7.5:
            vulnscore -= 0.10
            if RULES['highVuln'] not in offendingRules:
                offendingRules.append(RULES['highVuln'])
        elif 2.5 <= vData['cvss'] < 5:
            vulnscore -= 0.05
            if RULES['mediumVuln'] not in offendingRules:
                offendingRules.append(RULES['mediumVuln'])
        elif 0 < vData['cvss'] < 2.5:
            vulnscore -= 0.01
            if RULES['lowVuln'] not in offendingRules:
                offendingRules.append(RULES['lowVuln'])
        else:
            pass
    except KeyError:
        pass

if vulnscore < 0:
    vulnscore = 0.0

result = {
    "score_type": "vuln_score",
    "value": vulnscore,
    "timestamp": int(datetime.now().timestamp()),
    "rules": offendingRules
}
print(result)

exit(0)

# Init all the values as floats, so i will definitely be precise enough
count = 0.0
severity = 0.0
weight = 0.0
threshold = 0.0
percent = 0.0
weighted = 0.0
isZero = 0

# If the result contains values, for each row ...
if "rows" in datastore:
    for row in datastore["rows"]:
        count = row[0]
        severity = row[1]

        # ... detemine the standardized severity, the threshold value and the weight the severity has, ...
        if severity < 2.5:
                severity = 2.5
                threshold = 5000
                weight = 0.05
        if severity < 5:
                severity = 5
                threshold = 2500
                weight = 0.1
        if severity < 7.5:
                severity = 7.5
                threshold = 500
                weight = 0.15
        if severity >= 7.5:
                severity = 10
                threshold = 100
                weight = 0.2

        # ... calculate what the ratio between the vuln count and the threshold is, ...
        percent = count / threshold

        # ... calculate the weighted value ...
        weighted = percent * weight

        # ... and finally add the weighted score to the overall score.
        vulnscore = vulnscore + weighted

        # If the count exceeds the threshold the score must be 0.
        # As this is a for-loop it can happen, that the first iteration will make `isZero` = 1,
        # but the next will make it 0 again. To prevent that, the state will be check evertime.
        if count < threshold and isZero != 1:
            isZero = 0
        else:
            isZero = 1

# # If no threshold exceeds, print the score readable
# if isZero == 0:
#     print((1 - vulnscore) * 100)
# # If the threshold exceeds, the value must be 0
# else:
#     print(0)
