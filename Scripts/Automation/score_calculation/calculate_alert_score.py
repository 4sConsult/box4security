import json

# Read the contents of the result
file = open("alert_score_result.json", "r")

# Load content into a json datastore
datastore = json.load(file)

class AlertWeighting:
    def __init__(self, count, severity):
        self.count = count
        self.severity = severity
        self.weighting = 0
        self.threshold = 0
        self.fullfillment = 0
        self.weightingPercent = 0
        self.calculation = 0

    def calcThreshold(self):
        if self.severity == 1:
                self.threshold = 100000
        if self.severity == 2:
                self.threshold = 10000
        if self.severity == 3:
                self.threshold = 100
        if self.severity == 4:
                self.threshold = 10
        if self.severity == 5:
                self.threshold = 0

    def calcWeighting(self, sumCount):
        self.weighting = pow(self.severity * sumCount, 2) / sumCount
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
alarmscore = 0
weightings = []

for row in datastore["rows"]:
    w = AlertWeighting(row[0], row[1])
    w.calcThreshold()
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

alarmscore = 1 - (sumCalculation / sumWeightingPercent)
print(alarmscore)

