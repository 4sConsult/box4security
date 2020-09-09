import json
from datetime import datetime

# Setup variables for calculation.
# Each is dictionary, accessed by the keys gotten from Elasticsearch query. Refer to the query json.

# Weight of alarm severity.
WEIGHT = {
    'critical': 250,
    'high': 40,
    'medium': 1,
    'low': 0.1,
    'info': 0,
    'socialmedia': 15,
}

# Threshold of alarm severity.
# Define here above which state the severity category flags as 0.
# E.g. multiply num of vulnerabilities by their weight until THRESHOLD, then just set 0.
THRESHOLD = {
    'critical': 50,
    'high': 125,
    'medium': 10000,
    'low': 30000,
    'info': 1,
    'socialmedia': 9,
}

# List of rules
# Hold a dictionary which must have a `text` member for displaying measures to increase score.
RULES = {
    'critical': {'text': 'Mindestens ein Alarm von sehr hoher Schwere ist aufgetreten.'},
    'high': {'text': 'Mindestens ein Alarm von hoher Schwere ist aufgetreten.'},
    'medium': {'text': 'Mindestens ein Alarm von mittlere Schwere ist aufgetreten.'},
    'low': {'text': 'Mindestens ein Alarm von geringer Schwere ist aufgetreten.'},
    'info': {'text': 'Mindestens ein informativer Alarm ist aufgetreten.'},
    'socialmedia': {'text': 'Es wurde Social-Media-Aktivität erkannt.'}
}

# Calculate the total weight by summing up the dictionary.
totalWeight = sum(WEIGHT.values())
# Initialize score as 0
alertscore = 0.0
# List of offended rules from RULES.
offendingRules = []

# Read the contents of the result from Elasticsearch API query
file = open("/core4s/scripts/Automation/score_calculation/alerts_buckets.json", "r")
# Load content into a json datastore
datastore = json.load(file)

# the information is under this key. It is a list of buckets by severity
# 1, 2, 3, 4, 5
# as defined in the query json.
severitybuckets = datastore['aggregations']['severity']['buckets']

# for each severity bucket
for bucket in severitybuckets:
    severity = bucket['key']  # find out exactly which bucket we are looking at
    numAlerts = bucket['doc_count']
    if numAlerts:
        offendingRules.append(RULES[severity])  # RULE offended, add it.
    if numAlerts < THRESHOLD[severity]:  # Threshold not exceeded
        temp = numAlerts / THRESHOLD[severity]  # Calulate fraction of threshold that was exceeded.
    else:
        temp = 1  # Threshold exceeded => must take whole weight into account.
    temp *= WEIGHT[severity]  # multiply the fraction by weight e.g. weighted arithmetic mean, step 1
    alertscore += temp  # add the product to the alertscore e.g. weighted arithmetic mean, step 2

# social media rule
with open("/core4s/scripts/Automation/score_calculation/social_media_count.json", "r") as fsocial:
    dsSocial = json.load(fsocial)
    numSocial = dsSocial['count']
    if numSocial:
        offendingRules.append(RULES['socialmedia'])
    if numSocial < THRESHOLD['socialmedia']:
        temp = numSocial / THRESHOLD['socialmedia']
    else:
        temp = 1
    temp *= WEIGHT['socialmedia']
    alertscore += temp


alertscore = alertscore / totalWeight  # weighted arithmetic mean, step 3
alertscore = 1 - alertscore  # turn the percentage of not fulfilled into fulfilled 100%-X
alertscore = round(alertscore * 100, 2)  # 0.0047234234 => 0.0047 => 0.47%


result = {
    "score_type": "alert_score",
    "value": alertscore,
    "timestamp": int(datetime.utcnow().timestamp()) * 1000,
    "rules": offendingRules
}

with open('/tmp/alerts.scores.json', 'w') as tmpAlerts:
    json.dump(result, tmpAlerts)

print(result['value'])
