import json

# Read the contents of the result
file = open("/home/amadmin/box4s/scripts/Automation/score_calculation/alert_score_result.json", "r")

# Load content into a json datastore
datastore = json.load(file)

alarmscore = 0
count = 0
severity = 0
weight = 0
threshold = 0
percent = 0
weighted = 0
isZero = 0

if "rows" in datastore:
    for row in datastore["rows"]:
        count = row[0]
        severity = row[1]

#        if severity == 1:
#                threshold = 300
#                weight = 0.05
#        if severity == 2:
#                threshold = 150
#                weight = 0.1
#        if severity == 3:
#                threshold = 10
#                weight = 0.15
#        if severity == 4:
#                threshold = 3
#                weight = 0.2
#        if severity == 5:
#                threshold = 1
#                weight = 0.5

        if severity == 1:
                threshold = 2000
                weight = 0.05
        if severity == 2:
                threshold = 1000
                weight = 0.1
        if severity == 3:
                threshold = 600
                weight = 0.15
        if severity == 4:
                threshold = 250
                weight = 0.2
        if severity == 5:
                threshold = 100
                weight = 0.5

        percent = count / threshold
        weighted = percent * weight
        alarmscore = alarmscore + weighted

    if count < threshold and isZero != 1:
        isZero = 0
    else:
        isZero = 1

    print(str(count) + " " + str(severity) + " " + str(threshold) + " " + str(weight) + " " + str(weighted) + " " + str(alarmscore) + " " + str(isZero))
else:
    alarmscore = 100

if isZero == 0:
    print(alarmscore)
else:
    print(0)
