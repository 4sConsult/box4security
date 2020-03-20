from WebApp import app, models
from flask_restful import Resource, reqparse, abort


class BPF(Resource):
    def get(self, rule_id):
        rule = models.BPFRule.query.get(rule_id)
        if rule:
            return models.BPF.dump(rule)
        else:
            abort(404, message="BPF Rule with ID {} not found".format(rule_id))

    def post(self):
        return {}, 501

    def put(self):
        return {}, 501

    def delete(self):
        return {}, 501


class BPFs(Resource):
    def get(self):
        rules = models.BPFRule.query.all()
        return models.BPFs.dump(rules)


class LSR(Resource):
    def get(self, rule_id):
        rule = models.LogstashRule.get(rule_id)
        if rule:
            return models.LSR.dump(rule)
        else:
            abort(404, message="Logstash Rule with ID {} not found".format(rule_id))

    def post(self):
        return {}, 501

    def put(self):
        return {}, 501

    def delete(self):
        return {}, 501


class LSRs(Resource):
    def get(self):
        rules = models.LogstashRule.query.all()
        return models.LSRs.dump(rules)


class Alert(Resource):
    def get(self, alert_id):
        return {}, 501

    def post(self):
        return {}, 501

    def put(self):
        return {}, 501

    def delete(self):
        return {}, 501
