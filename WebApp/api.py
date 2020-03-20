from WebApp import app, models, db
from flask_restful import Resource, reqparse, abort
from flask import request


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
        return {}, 405

    def delete(self):
        return {}, 501


class BPFs(Resource):
    def get(self):
        rules = models.BPFRule.query.all()
        return models.BPFs.dump(rules)

    def post(self):
        return self.put()

    def put(self):
        d = request.json
        newRule = models.BPFRule(
            src_ip=d['src_ip'],
            src_port=d['src_port'],
            dst_ip=d['dst_ip'],
            dst_port=d['dst_port'],
            proto=d['proto'],
        )
        db.session.add(newRule)
        db.session.commit()
        return models.BPF.dump(newRule)


class LSR(Resource):
    def get(self, rule_id):
        rule = models.LogstashRule.query.get(rule_id)
        if rule:
            return models.LSR.dump(rule)
        else:
            abort(404, message="Logstash Rule with ID {} not found".format(rule_id))

    def post(self):
        abort(405, message="Not allowed.")

    def put(self):
        abort(405, message="Not allowed.")

    def delete(self):
        return {}, 501


class LSRs(Resource):
    def get(self):
        rules = models.LogstashRule.query.all()
        return models.LSRs.dump(rules)

    def post(self):
        return self.put()

    def put(self):
        d = request.json
        newRule = models.LogstashRule(
            src_ip=d['src_ip'],
            src_port=d['src_port'],
            dst_ip=d['dst_ip'],
            dst_port=d['dst_port'],
            proto=d['proto'],
            signature_id=d['signature_id'],
            signature=d['signature']
        )
        db.session.add(newRule)
        db.session.commit()
        return models.LSR.dump(newRule)

    def delete(self):
        return {}, 501


class Alert(Resource):
    def get(self, alert_id):
        return {}, 501

    def post(self):
        return {}, 501

    def put(self):
        return {}, 501

    def delete(self):
        return {}, 501
