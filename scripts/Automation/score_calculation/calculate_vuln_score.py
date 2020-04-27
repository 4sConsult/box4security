import json

# Read the contents of the result
file = open("/home/amadmin/box4s/scripts/Automation/score_calculation/vuln_score_result.json", "r")

# Load content into a json datastore
datastore = json.load(file)

vulnscore = 0.0
count = 0.0
severity = 0.0
weight = 0.0
threshold = 0.0
percent = 0.0
weighted = 0.0
isZero = 0

if "rows" in datastore:
    for row in datastore["rows"]:
        count = row[0]
        severity = row[1]

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

        percent = count / threshold
        weighted = percent * weight
        vulnscore = vulnscore + weighted

        if count < threshold and isZero != 1:
            isZero = 0
        else:
            isZero = 1
else:
    vulnscore = 100

if isZero == 0:
    print(vulnscore)
else:
    print(0)
