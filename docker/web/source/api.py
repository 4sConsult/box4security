from source import app, models, db
from flask_restful import Resource, reqparse, abort
from flask import request, render_template
import requests
import jinja2
import os
import json
import io
import subprocess


def tail(f, window=1):
    """
    Returns the last `window` lines of file `f` as a list of bytes.
    """
    # https://stackoverflow.com/a/48087596
    if window == 0:
        return b''
    BUFSIZE = 1024
    f.seek(0, 2)
    end = f.tell()
    nlines = window + 1
    data = []
    while nlines > 0 and end > 0:
        i = max(0, end - BUFSIZE)
        nread = min(end, BUFSIZE)

        f.seek(i)
        chunk = f.read(nread)
        data.append(chunk)
        nlines -= chunk.count(b'\n')
        end -= nread
    return b'\n'.join(b''.join(reversed(data)).splitlines()[-window:])


def writeLSRFile():
    # Fetches all Logstash Rules from DB and writes to correct file
    # TODO: check permissions / try error
    with open('/var/lib/box4s/15_logstash_suppress.conf', 'w') as f_logstash:
        rules = models.LogstashRule.query.all()
        filled = render_template('15_logstash_suppress.conf.j2', rules=rules)
        f_logstash.write(filled)


def writeBPFFile():
    # Fetches all BPF Rules from DB and writes to correct file
    # Then restarts suricata
    # TODO: check permissions / Try error
    with open('/var/lib/box4s/suricata_suppress.bpf', 'w') as f_bpf:
        rules = models.BPFRule.query.all()
        filled = render_template('suricata_suppress.bpf.j2', rules=rules)
        f_bpf.write(filled)
        # read pw from $SSHPASS and login to dockerhost to execute restartSuricata
        os.system(f'sshpass -e ssh -o StrictHostKeyChecking=no amadmin@dockerhost sudo /home/amadmin/restartSuricata.sh')


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


class Version(Resource):
    def get(self):
        # return currently installed version
        CURRVER = os.getenv('VERSION')
        return {'version': CURRVER}


class AvailableReleases(Resource):
    def get(self):
        # return available releases from gitlab
        try:
            git = requests.get('https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags',
                               headers={'PRIVATE-TOKEN': os.getenv('GIT_TOKEN')}).json()
        except Exception:
            abort(408, message="GitLab API Timeout")
        else:
            # take only relevant info
            res = [{'version': tag['name'], 'message': tag['message'], 'date': tag['commit']['created_at'], 'changelog': tag['release']['description'] if tag['release'] else ''} for tag in git]
            return res


class LaunchUpdate(Resource):
    def __init__(self):
        # Register Parser and argument for endpoint
        self.parser = reqparse.RequestParser()
        self.parser.add_argument('target', type=str)
        self.args = self.parser.parse_args()

    def post(self):
        # launch update.sh with target version
        # targetVersion = self.args['target']
        subprocess.Popen('sshpass -e ssh -o StrictHostKeyChecking=no amadmin@dockerhost sudo /home/amadmin/box4s/BOX4s-main/update.sh', shell=True)
        return {"message": "accepted"}, 200


class UpdateLog(Resource):
    def get(self):
        # Return last 15 lines of updatelog file
        with open('/var/log/box4s/update.log', 'rb') as f:
            lastLines = tail(f, 15).decode('utf-8').splitlines()
            return {'lines': lastLines}, 200


class UpdateStatus(Resource):
    def __init__(self):
        # Argument parser
        self.parser = reqparse.RequestParser()

    def get(self):
        # return status of update
        with open('/var/lib/box4s/.update.state', 'r') as f:
            # Remove whitespaces and newlines from line
            status = f.readline().strip().rstrip()
            return {'status': status}, 200

    def post(self):
        # set new status of update
        self.parser.add_argument('status', type=str)
        self.args = self.parser.parse_args()
        with open('/var/lib/box4s/.update.state', 'w') as f:
            f.write(self.args['status'])
            return {}, 200

    def delete(self):
        # empty update state file
        f = open('/var/lib/box4s/.update.state', 'w')
        f.close()
        return {}, 205


class Alert(Resource):
    def get(self, alert_id):
        return {}, 501

    def post(self):
        return {}, 501

    def put(self):
        return {}, 501

    def delete(self):
        return {}, 501
