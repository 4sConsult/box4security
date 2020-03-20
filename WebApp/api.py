from flask import Flask
from flask_restful import Resource, Api, reqparse, abort


app = Flask(__name__)
api = Api(app)

bpfrules = {
    1: {'src_ip': '127.0.0.1', 'src_port': 0, 'dst_ip': '0.0.0.0', 'dst_port': 0, 'proto': ''},
    2: {'dst_ip': '127.0.0.1', 'src_port': 0, 'src_ip': '0.0.0.0', 'dst_port': 0, 'proto': ''},
}


def abort_if_not_exist(rule_id):
    if rule_id not in bpfrules:
        abort(404, message="Rule {} doesn't exist".format(rule_id))


class BPFRule(Resource):
    def get(self, rule_id):
        abort_if_not_exist(rule_id)
        return bpfrules[rule_id]

    def post(self):
        return {}, 501

    def put(self):
        return {}, 501

    def delete(self):
        return {}, 501


class BPFRuleList(Resource):
    def get(self):
        return bpfrules


class LogstashRule(Resource):
    def get(self, rule_id):
        return {}, 501

    def post(self):
        return {}, 501

    def put(self):
        return {}, 501

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


api.add_resource(BPFRule, '/rules/bpf/<int:rule_id>')
api.add_resource(BPFRuleList, '/rules/bpf/')
api.add_resource(LogstashRule, '/rules/logstash/<int:rule_id>')
api.add_resource(Alert, '/alert/<int:alert_id>')

if __name__ == '__main__':
    app.run(debug=True)
