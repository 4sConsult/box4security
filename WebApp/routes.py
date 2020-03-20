from WebApp import app
from .api import BPF, BPFs, LSR, LSRs, Alert
from flask_restful import Api

api = Api(app)

api.add_resource(BPF, '/rules/bpf/<int:rule_id>')
api.add_resource(BPFs, '/rules/bpf/')
api.add_resource(LSR, '/rules/logstash/<int:rule_id>')
api.add_resource(LSRs, '/rules/logstash/')
api.add_resource(Alert, '/alert/<int:alert_id>')
