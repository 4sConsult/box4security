from source import app, models, db
from flask_restful import Resource, reqparse, abort
from flask import request
import jinja2
import os
templateLoader = jinja2.FileSystemLoader(searchpath="")
templateEnv = jinja2.Environment(loader=templateLoader)


def writeLSRFile():
    # Fetches all Logstash Rules from DB and writes to correct file
    # TODO: check permissions / try error
    # /var/www/kibana/ebpf/
    with open('15_kibana_filter.conf', 'w') as f_logstash:
        rules = models.LogstashRule.query.all()
        template = templateEnv.get_template('templates/15_kibana_filter.conf.j2')
        f_logstash.write(template.render({'rules': rules}))


def writeBPFFile():
    # Fetches all BPF Rules from DB and writes to correct file
    # Then restarts suricata
    # TODO: check permissions / Try error
    # /var/www/kibana/ebpf/
    with open('bypass_filter.bpf', 'w') as f_bpf:
        rules = models.BPFRule.query.all()
        template = templateEnv.get_template('templates/bypass_filter.bpf.j2')
        f_bpf.write(template.render({'rules': rules}))
        os.system('/var/www/kibana/html/restartSuricata.sh')


class BPF(Resource):
    def get(self, rule_id):
        rule = models.BPFRule.query.get(rule_id)
        if rule:
            return models.BPF.dump(rule)
        else:
            abort(404, message="BPF Rule with ID {} not found".format(rule_id))

    def post(self):
        abort(405, message="Cannot update or post directly to a rule ID.")

    def put(self):
        abort(405, message="Cannot update or post directly to a rule ID.")

    def delete(self, rule_id):
        rule = models.BPFRule.query.get(rule_id)
        if rule:
            db.session.delete(rule)
            db.session.commit()
            # newly write file because rules have changed and restart suricata
            writeBPFFile()
            return '', 204
        else:
            abort(404, message="BPF Rule with ID {} not found. Nothing deleted.".format(rule_id))


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
        # Add new rule to db
        db.session.add(newRule)
        db.session.commit()
        # newly write file because rules have changed and restart suricata
        writeBPFFile()
        return models.BPF.dump(newRule)

    def delete(self):
        models.BPFRule.query.delete()
        db.session.commit()
        writeBPFFile()
        return '', 204


class LSR(Resource):
    def get(self, rule_id):
        rule = models.LogstashRule.query.get(rule_id)
        if rule:
            return models.LSR.dump(rule)
        else:
            abort(404, message="Logstash Rule with ID {} not found".format(rule_id))

    def post(self):
        abort(405, message="Cannot update or post directly to a rule ID.")

    def put(self):
        abort(405, message="Cannot update or post directly to a rule ID.")

    def delete(self, rule_id):
        rule = models.LogstashRule.query.get(rule_id)
        if rule:
            db.session.delete(rule)
            db.session.commit()
            # newly write file because rules have changed
            writeLSRFile()
            return '', 204
        else:
            abort(404, message="Logstash Rule with ID {} not found. Nothing deleted.".format(rule_id))


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
        # Add new rule to db
        db.session.add(newRule)
        db.session.commit()
        # newly write file because rules have changed
        writeLSRFile()
        return models.LSR.dump(newRule)

    def delete(self):
        models.LogstashRule.query.delete()
        db.session.commit()
        writeLSRFile()
        return '', 204


class Update(Resource):
    def get(self, alert_id):
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
