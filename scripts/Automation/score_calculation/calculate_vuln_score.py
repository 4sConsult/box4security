import json

# Read the contents of the result
file = open("/home/amadmin/box4s/scripts/Automation/score_calculation/vuln_score_result.json", "r")

# Load content into a json datastore
datastore = json.load(file)

class VulnWeighting:
    def __init__(self, count, severity):
        self.count = count
        self.severity = severity
        self.severityRounded = 0
        self.weighting = 0
        self.threshold = 0
        self.fullfillment = 0
        self.weightingPercent = 0
        self.calculation = 0

    def calcThreshold(self):
        if self.severity < 2.5:
                self.threshold = 1000
        if self.severity < 5:
                self.threshold = 20
        if self.severity < 7.5:
                self.threshold = 10
        if self.severity >= 7.5:
                self.threshold = 2

    def calcThresholdRounded(self):
        if self.threshold == 1000:
            self.severityRounded = 2.5
        if self.threshold == 20:
            self.severityRounded = 5
        if self.threshold == 10:
            self.severityRounded = 7.5
        if self.threshold == 2:
            self.severityRounded = 10

    def calcWeighting(self, sumCount):
        self.weighting = pow(self.severityRounded * sumCount, 2) / sumCount
        return self.weighting

    def calcWeightingPercent(self, maxWeighting):
        self.weightingPercent = self.weighting / maxWeighting
        return self.weightingPercent

    def calcFullfillment(self):
        if (1 - self.count / self.weighting) >= 0:
                self.fullfillment = 1 - self.count / self.weighting
        else:
                self.fullfillment = 0
        return self.fullfillment

    def calcCalculation(self):
        self.calculation = self.fullfillment * self.weightingPercent
        return self.calculation

sumCount = 0
maxWeighting = 0
sumCalculation = 0
sumWeightingPercent = 0
vulnscore = 0
weightings = []

if "rows" in datastore:
    for row in datastore["rows"]:
    	w = VulnWeighting(row[0], row[1])
    	w.calcThreshold()
    	w.calcThresholdRounded()
    	weightings.append(w)

    for w in weightings:
    	sumCount += w.count

    for w in weightings:
    	w.calcWeighting(sumCount)

    for w in weightings:
    	if w.weighting >= maxWeighting:
            maxWeighting = w.weighting

    for w in weightings:
    	w.calcWeightingPercent(maxWeighting)
    	w.calcFullfillment()
    	w.calcCalculation()

    for w in weightings:
    	sumCalculation += w.calculation
    	sumWeightingPercent += w.weightingPercent

    vulnscore = (1 - (sumCalculation / sumWeightingPercent)) * 100
else:
    vulnscore = 100
print(vulnscore)

