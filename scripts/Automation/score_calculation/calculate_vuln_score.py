import json

# Read the contents of the result
file = open("/home/amadmin/box4s/scripts/Automation/score_calculation/vuln_score_result.json", "r")

# Load content into a json datastore
datastore = json.load(file)

# Init all the values as floats, so i will definitely be precise enough
vulnscore = 0.0
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

        # If no threshold exceeds, print the score readable
        if isZero == 0:
            print((1 - vulnscore) * 100)
        # If the threshold exceeds, the value must be 0
        else:
            print(0)

# If the result doesn't contain any results, there seem to be no vulnerabilities. Great!
else:
    vulnscore = 100
    print(vulnscore)
