"""Module for webapp API."""
from source import models, db, helpers
from flask_restful import Resource, reqparse, abort, marshal, fields
from flask_user import login_required, current_user, roles_required
from flask import request, render_template, send_file, jsonify, send_from_directory
from source.wizard.models import Network, NetworkType, System, SystemType
from source.wizard.schemas import SYS, SYSs, NET, NETs
from source.wizard.middleware import WizardMiddleware
import tempfile
import requests
import os
import time
import subprocess
import json
from shlex import quote
from requests.exceptions import Timeout, ConnectionError
from datetime import datetime
from werkzeug.utils import secure_filename
import docker


def tail(f, window=1):
    """Return the last `window` lines of file `f` as a list of bytes."""
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


def restartContainer(name=None):
    """Restart a Docker container via Docker API."""
    client = docker.from_env()
    if name:
        try:
            container = client.containers.get(name)
            container.restart()
        except (docker.errors.APIError, docker.errors.NotFound):
            return None
    return name


def writeLSRFile():
    """Write all Logstash Rules from DB to correct file."""
    # TODO: check permissions / try error
    with open('/var/lib/box4s/15_logstash_suppress.conf', 'w') as f_logstash:
        rules = models.LogstashRule.query.all()
        filled = render_template('15_logstash_suppress.conf.j2', rules=rules)
        f_logstash.write(filled)


def writeBPFFile():
    """Write all Suricata Rules from DB to correct file and restart Suricata."""
    # TODO: check permissions / Try error
    with open('/var/lib/box4s/suricata_suppress.bpf', 'w') as f_bpf:
        rules = models.BPFRule.query.all()
        filled = render_template('suricata_suppress.bpf.j2', rules=rules)
        f_bpf.write(filled)
        _ = restartContainer("suricata")
        # TODO: Log/Display Error.


def writeAlertFile(alert):
    """Write an alert dict to file."""
    # TODO: check permissions / Try error
    with open(f'/var/lib/elastalert/rules/{ alert["safe_name"] }.yaml', 'w') as f_alert:
        filled = render_template(f'application/{ alert["type"] }.yaml.j2', alert=alert)
        f_alert.write(filled)


def allowed_file_snaphsot(filename, extension):
    """Helper for Snapshots - only allows files with specified extension to be uploaded"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in extension


def enableQuickAlert(key, email, smtp={}):
    """Write a quick alert to file."""
    # TODO: check permissions / Try error
    if not smtp:
        smtp = {
            'host': os.getenv('MAIL_SERVER'),
            'port': os.getenv('MAIL_PORT'),
            'tls': os.getenv('MAIL_USE_TLS'),
            'sender': os.getenv('MAIL_DEFAULT_SENDER'),
        }
    yaml = render_template(f"application/quick_alert_{  key }.yaml.j2", target=email, smtp=smtp)
    response = requests.post(f"http://elastalert:3030/rules/quick_{  key }", json={'yaml': yaml})
    return response


def restartBOX4s(sleep=10):
    """Restart the BOX4s after sleeping for `sleep` seconds (default=10)."""
    strSeconds = str(sleep)
    subprocess.Popen(['sleep', strSeconds])
    runHostCommand('sudo systemctl restart box4security')


def runHostCommand(cmd=None):
    if cmd:
        cmd += '\n'
        with open('/var/lib/box4s/web.pipe', 'w') as pipe:
            pipe.write(quote(cmd))


def writeSMTPConfig(config):
    """Write the SMTP config to the corresponding files.

    Writes:
        - /etc/box4s
        - /etc/msmtprc
        - /var/lib/box4s/elastalertsmtp.yaml

    Expects a Python dictionary that has the keys for config.
    """
    with open('/etc/box4s/smtp.conf', 'w') as etc_smtp:
        filled = render_template('application/smtp.conf.j2', smtp=config)
        etc_smtp.write(filled)
    with open('/etc/box4s/msmtprc', 'w') as etc_msmtp:
        filled = render_template('application/msmtprc.j2', smtp=config)
        etc_msmtp.write(filled)
    with open('/var/lib/box4s/elastalert_smtp.yaml', 'w') as varlib_elastalertsmtp:
        filled = render_template('application/elastalert_smtp.yaml.j2', smtp=config)
        varlib_elastalertsmtp.write(filled)
        # Newly set rules with changed smtp config
        try:
            with open('/var/lib/box4s/alert_mail.conf') as fd:
                alert_mail = fd.read().strip()
        except FileNotFoundError:
            alert_mail = "box@4sconsult.de"
        try:
            ea = requests.get("http://elastalert:3030/rules").json()
            for key in ea['rules']:
                if key.startswith('quick'):
                    key = key.replace('quick_', '')
                    # Check key whitelist
                    if key in ['malware', 'ids', 'vuln', 'netuse']:
                        enableQuickAlert(key=key, email=alert_mail, smtp=config)
        except Timeout:
            abort(504, message="Alert API Timeout")
        except ConnectionError:
            abort(503, message="Alert API unreachable")
        except Exception:
            abort(502, message="Alert API Failure")


class Repair(Resource):
    """API Resource for starting a Repair Script."""

    @roles_required(['Super Admin'])
    def put(self):
        """Execute Repair Script"""
        value = request.json['key']
        runHostCommand(cmd=f"sudo bash $BOX4s_INSTALL_DIR/scripts/1stLevelRepair/repair_{ value }.sh")
        return {"message": "accepted"}, 200

    @roles_required(['Super Admin'])
    def get(self):
        """Deny deleting Reapir Script."""
        abort(405, message="Cannot GET Repair Script.")

    @roles_required(['Super Admin'])
    def post(self):
        """Forward Repair."""
        return self.put()

    @roles_required(['Super Admin'])
    def delete(self):
        """Deny deleting Reapir Script."""
        abort(405, message="Cannot delete Repair Script.")


class SnapshotInfo(Resource):
    """API for gathering info about snapshots or creating a new snapshot and Uploading a snapshot"""

    @roles_required(['Super Admin'])
    def get(self):
        """Gather info for all Snapshots"""
        snap_folder = "/var/lib/box4s/snapshots"
        if not os.path.exists(snap_folder):
            os.makedirs(snap_folder)
        files = {}
        files['snapshots'] = []
        for filename in os.listdir(snap_folder):
            path = os.path.join(snap_folder, filename)
            if os.path.isfile(path) and allowed_file_snaphsot(filename, ['zip']):
                time_snap = datetime.fromtimestamp(os.path.getctime(path))
                files['snapshots'].append({'name': filename, 'date': time_snap})
        return jsonify(files)

    @roles_required(['Super Admin'])
    def post(self):
        """Create a snapshot"""
        runHostCommand(cmd="sudo bash $BOX4s_INSTALL_DIR/scripts/1stLevelRepair/repair_createSnapshot.sh")
        return {"message": "accepted"}, 200

    @roles_required(['Super Admin'])
    def put(self):
        """Upload a Snapshot"""
        file = request.files['file']
        snap_folder = "/var/lib/box4s/snapshots"
        if file.filename == '':
            abort(403)
        if file and allowed_file_snaphsot(file.filename, ['zip']):
            filename = secure_filename(file.filename)
            file.save(os.path.join(snap_folder, filename))
            return {"message": "uploaded"}, 200
        return ''


class SnapshotFileHandler(Resource):
    """API for interacting with Snapshot File Requests"""

    @roles_required(['Super Admin'])
    def get(self, filename):
        """Download a Snapshot"""
        snap_folder = "/var/lib/box4s/snapshots"
        if filename and allowed_file_snaphsot(filename, ['zip']):
            return send_from_directory(snap_folder, filename, as_attachment=True)
        else:
            abort(404, message="Cannot download this file.")

    @roles_required(['Super Admin'])
    def post(self, filename):
        """Restore a Snapshot"""
        runHostCommand(cmd=f"sudo bash $BOX4s_INSTALL_DIR/scripts/1stLevelRepair/repair_snapshot.sh { filename }")
        return {"message": "accepted"}, 200

    @roles_required(['Super Admin'])
    def delete(self, filename):
        """Delete Snapshot"""
        snap_folder = "/var/lib/box4s/snapshots"
        if allowed_file_snaphsot(filename, ['zip']):
            try:
                os.remove(os.path.join(snap_folder, filename))
            except OSError:
                pass
            return {"message": "accepted"}, 200
        else:
            abort(404, message="Cannot delete this file.")


class BPF(Resource):
    """API Resource for a single BPF Rule."""

    @roles_required(['Super Admin', 'Filter'])
    def get(self, rule_id):
        """Get a single BPF Rule by id."""
        rule = models.BPFRule.query.get(rule_id)
        if rule:
            return models.BPF.dump(rule)
        else:
            abort(404, message="BPF Rule with ID {} not found".format(rule_id))

    @roles_required(['Super Admin', 'Filter'])
    def post(self):
        """Deny updating BPF Rule."""
        abort(405, message="Cannot update or post directly to a rule ID.")

    @roles_required(['Super Admin', 'Filter'])
    def put(self):
        """Deny updating BPF Rule."""
        abort(405, message="Cannot update or post directly to a rule ID.")

    @roles_required(['Super Admin', 'Filter'])
    def delete(self, rule_id):
        """Delete a single BPF Rule by id."""
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
    """API Resource for a set of BPF Rules."""

    @roles_required(['Super Admin', 'Filter'])
    def get(self):
        """Return all BPF Rules."""
        rules = models.BPFRule.query.all()
        return models.BPFs.dump(rules)

    @roles_required(['Super Admin', 'Filter'])
    def post(self):
        """Implement a new BPF Rule by redirecting to PUT."""
        return self.put()

    @roles_required(['Super Admin', 'Filter'])
    def put(self):
        """Implement a new BPF Rule."""
        d = request.json
        newRule = models.BPFRule(
            src_ip=d['src_ip'] if d['src_ip'] else "0.0.0.0",
            src_port=d['src_port'] if d['src_port'] else 0,
            dst_ip=d['dst_ip'] if d['dst_ip'] else "0.0.0.0",
            dst_port=d['dst_port'] if d['dst_port'] else 0,
            proto=d['proto'],
        )
        # Add new rule to db
        db.session.add(newRule)
        db.session.commit()
        # newly write file because rules have changed and restart suricata
        writeBPFFile()
        return models.BPF.dump(newRule)

    @roles_required(['Super Admin', 'Filter'])
    def delete(self):
        """Delete all BPF Rules from database."""
        models.BPFRule.query.delete()
        db.session.commit()
        writeBPFFile()
        return '', 204


class LSR(Resource):
    """API Resource for a single Logstash Rule."""

    @roles_required(['Super Admin', 'Filter'])
    def get(self, rule_id):
        """Get a single Logstash Rule by id."""
        rule = models.LogstashRule.query.get(rule_id)
        if rule:
            return models.LSR.dump(rule)
        else:
            abort(404, message="Logstash Rule with ID {} not found".format(rule_id))

    @roles_required(['Super Admin', 'Filter'])
    def post(self):
        """Deny updating Logstash Rule."""
        abort(405, message="Cannot update or post directly to a rule ID.")

    @roles_required(['Super Admin', 'Filter'])
    def put(self):
        """Deny updating Logstash Rule."""
        abort(405, message="Cannot update or post directly to a rule ID.")

    @roles_required(['Super Admin', 'Filter'])
    def delete(self, rule_id):
        """Delete Logstash Rule by id."""
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
    """API Resource for a set of Logstash Rules."""

    @roles_required(['Super Admin', 'Filter'])
    def get(self):
        """Return all Logstash Rules."""
        rules = models.LogstashRule.query.all()
        return models.LSRs.dump(rules)

    @roles_required(['Super Admin', 'Filter'])
    def post(self):
        """Implement new Logstash Rule by redirecting to PUT."""
        return self.put()

    @roles_required(['Super Admin', 'Filter'])
    def put(self):
        """Implement new Logstash Rule."""
        d = request.json
        newRule = models.LogstashRule(
            src_ip=d['src_ip'] if d['src_ip'] else "0.0.0.0",
            src_port=d['src_port'] if d['src_port'] else 0,
            dst_ip=d['dst_ip'] if d['dst_ip'] else "0.0.0.0",
            dst_port=d['dst_port'] if d['dst_port'] else 0,
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

    @roles_required(['Super Admin', 'Filter'])
    def delete(self):
        """Delete all Logstash Rules from database."""
        models.LogstashRule.query.delete()
        db.session.commit()
        writeLSRFile()
        return '', 204


class Version(Resource):
    """API Resource for working with the current version."""

    def get(self):
        """
        GET currently installed version and environment.

        Allowed for `Updates`, `Super Admin` role or request from the docker host.

        version is a semantic version string
        env specifies the environment: prod (default) or dev
        """
        CURRVER = os.getenv('VERSION')
        if request.headers.get('x-forwarded-for') == '172.20.8.1':
            # request from docker host, allow
            return {'version': CURRVER, 'env': os.getenv('BOX4s_ENV', 'production')}
        elif current_user.is_authenticated and current_user.has_role('Updates'):
            # request from allowed role
            return {'version': CURRVER, 'env': os.getenv('BOX4s_ENV', 'production')}
        else:
            abort(403, message="Forbidden.")


class AvailableReleases(Resource):
    """API Resource for working with all available releases."""

    def get(self):
        """GET: fetch and return all available releases with their relevant info from GitLab.
        Allowed for `Updates`, `Super Admin` role or request from the docker host.
        """
        if not (current_user.is_authenticated and current_user.has_role('Updates')) and not request.headers.get('x-forwarded-for') == '172.20.8.1':
            abort(403, message="Forbidden.")

        try:
            git = requests.get('https://api.github.com/repos/4sConsult/box4security/releases',
                               headers={'Accept': 'application/vnd.github.v3+json'}).json()
        except Timeout:
            abort(504, message="GitHub API Timeout")
        except ConnectionError:
            abort(503, message="GitHub API unreachable")
        except Exception:
            abort(502, message="GitHub API Failure")
        else:
            # take only relevant info
            res = [{'version': tag['tag_name'], 'message': tag['name'], 'date': tag['published_at'], 'changelog': tag['body'] if tag['body'] else ''} for tag in git]
            return res


class LaunchUpdate(Resource):
    """Launch an update."""

    def __init__(self):
        """Register Parser and argument for endpoint.

        `target` is the target version for the update.
        """
        self.parser = reqparse.RequestParser()
        self.parser.add_argument('target', type=str)
        self.args = self.parser.parse_args()

    @roles_required(['Super Admin', 'Updates'])
    def post(self):
        """Launch update.sh."""
        # targetVersion = self.args['target']
        runHostCommand(cmd="sudo $BOX4s_INSTALL_DIR/scripts/Automation/update.sh")
        return {"message": "accepted"}, 200


class UpdateLog(Resource):
    """API representation of the Update Log Endpoint."""

    @roles_required(['Super Admin', 'Updates'])
    def get(self):
        """Return last 15 lines of updatelog file."""
        with open('/var/log/box4s/update.log', 'rb') as f:
            lastLines = tail(f, 15).decode('utf-8').splitlines()
            return {'lines': lastLines}, 200


class UpdateStatus(Resource):
    """API representation of the update status.

    Available options are getting, setting and deleting.
    """

    def __init__(self):
        """Initialize Request Parser."""
        self.parser = reqparse.RequestParser()

    @roles_required(['Super Admin', 'Updates'])
    def get(self):
        """Get update status."""
        with open('/var/lib/box4s/.update.state', 'r') as f:
            # Remove whitespaces and newlines from line
            status = f.readline().strip().rstrip()
            return {'status': status}, 200

    def post(self):
        """Set new update status.
        Allowed for `Updates`, `Super Admin` role or request from the docker host.
        """
        self.parser.add_argument('status', type=str)
        self.args = self.parser.parse_args()

        if not (current_user.is_authenticated and current_user.has_role('Updates')) and not request.headers.get('x-forwarded-for') == '172.20.8.1':
            abort(403, message="Forbidden.")

        with open('/var/lib/box4s/.update.state', 'w') as f:
            f.write(self.args['status'])
            return {}, 200

    def delete(self):
        """Empty update state file.
        Allowed for `Updates`, `Super Admin` role or request from the docker host.
        """
        if not (current_user.is_authenticated and current_user.has_role('Updates')) and not request.headers.get('x-forwarded-for') == '172.20.8.1':
            abort(403, message="Forbidden.")
        f = open('/var/lib/box4s/.update.state', 'w')
        f.close()
        return {}, 205


class Alert(Resource):
    """API representation of a single alert by ID.

    Read, Update and Delete are wrapping around the ElastAlert API (https://github.com/bitsensor/elastalert#api).
    Creating is creating a yaml rule file in the rulePath.
    """

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()
        self.parser.add_argument('yaml', type=str)

    @roles_required(['Super Admin', 'Alerts'])
    def get(self, alert_id):
        """Read a single Alert Rule by ID.

        Wraps around ElastAlert's /rules/:id
        """
        response = requests.get(f"http://elastalert:3030/rules/{alert_id}")
        try:
            response = response.json()
            # is already json => return
            return response
        except json.JSONDecodeError:
            # make json and return it
            return json.dumps(response.text)

    @roles_required(['Super Admin', 'Alerts'])
    def post(self, alert_id):
        """Add/Edit/Update a single Alert Rule by ID.

        Wraps around ElastAlert's /rules/:id
        """
        return requests.post(f"http://elastalert:3030/rules/{alert_id}", json=json.dumps({'yaml': self.args['yaml']})).json()

    @roles_required(['Super Admin', 'Alerts'])
    def delete(self, alert_id):
        """Delete a single Alert Rule by ID.

        Wraps around ElastAlert's /rules/:id
        """
        response = requests.delete(f"http://elastalert:3030/rules/{alert_id}")
        try:
            response = response.json()
            return response
        except json.JSONDecodeError:
            # ElastAlert does not return a valid json response, when deleting stuff successfully, apparently.
            return {}, 204


class Alerts(Resource):
    """API representation of all alert rules."""

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()

    @roles_required(['Super Admin', 'Alerts'])
    def get(self):
        """Get all alert rules.

        Wrap around ElastAlert GET /rules endpoint:
        Returns a list of directories and rules that exist in the rulesPath (from the config) and are being run by the ElastAlert process.
        """
        try:
            ea = requests.get("http://elastalert:3030/rules")
            return ea.json()
        except Timeout:
            abort(504, message="Alert API Timeout")
        except ConnectionError:
            abort(503, message="Alert API unreachable")
        except Exception:
            abort(502, message="Alert API Failure")

    @roles_required(['Super Admin', 'Alerts'])
    def put(self):
        """Create a new alerting rule.

        Returns:
            [type] -- [description]
        """
        self.parser.add_argument('name', type=str)
        a = object()
        # Check if alert with this name exists
        # return error to notice web
        # Write alert to file
        writeAlertFile(a)
        return {}, 501


class AlertsQuick(Resource):
    """API representation of BOX4s Quick alert rules."""

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()
        self.parser.add_argument('key', type=str)
        self.parser.add_argument('email', type=str, required=False)
        try:
            self.args = self.parser.parse_args()
        except Exception:
            abort(400, message="Bad Request. Failed parsing arguments.")

    @roles_required(['Super Admin', 'Alerts'])
    def get(self):
        """Get all ENABLED Quick Alert Rules.

        Returns a list of enabled quick alert rules as json.
        """
        ea = requests.get("http://elastalert:3030/rules").json()
        resp = []
        for rule in ea['rules']:
            if rule.startswith('quick'):
                resp.append(rule)
        return resp

    @roles_required(['Super Admin', 'Alerts'])
    def put(self):
        """Enable BOX4s Quick Alert Rule.

        Accepts key from whitelist array.
        Denies with 400 if key not from the whitelist array.
        Calls function to write the corresponding prepared alert rule file to disk.
        Returns 202 and the key on success.
        TODO: Exception handling
        """
        if self.args['key'] not in ['malware', 'ids', 'vuln', 'netuse']:
            return {'key': self.args['key']}, 400
        if "email" not in self.args:
            abort(400, message="Bad Request. Missing email parameter.")
        response = enableQuickAlert(key=self.args['key'], email=self.args['email'])
        return response.json(), 202

    @roles_required(['Super Admin', 'Alerts'])
    def delete(self):
        """Disable BOX4s Quick Alert Rule.

        Accepts key from ['ids', 'vuln', 'netuse'].
        Denies with 400 if key not from the whitelist array.
        Deletes the rule corresponding to the specified key.
        Returns 204 on success.
        TODO: Exception handling
        """
        if self.args['key'] not in ['malware', 'ids', 'vuln', 'netuse']:
            return {'key': self.args['key']}, 400
        requests.delete(f"http://elastalert:3030/rules/quick_{ self.args['key'] }")
        return {}, 204


class AlertMailer(Resource):
    """BOX4s Alert Mailer Resource."""

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()

    @roles_required(['Super Admin', 'Alerts'])
    def get(self):
        """Get currently installed alert receiver email address.

        Success: Returns 200, {"email": "example@example.com"} on success
        Missing: Returns 404 if no email set.
        """
        try:
            with open('/var/lib/box4s/alert_mail.conf') as fd:
                alert_mail = fd.read()
                if alert_mail:
                    return {'email': alert_mail}, 200
                else:
                    return {}, 404
        except FileNotFoundError:
            return {}, 404

    @roles_required(['Super Admin', 'Alerts'])
    def put(self):
        """Write supplied `email` parameter to disk.

        Truncates previous content.
        Return 202 on success.
        """
        self.parser.add_argument('email', type=str)
        try:
            self.args = self.parser.parse_args()
        except Exception:
            abort(400, message="Bad Request. Failed parsing arguments.")
        with open('/var/lib/box4s/alert_mail.conf', 'w') as fd:
            fd.write(self.args['email'])

        return {}, 202

    @roles_required(['Super Admin', 'Alerts'])
    def post(self):
        """Write supplied `email` parameter to disk by redirecting to PUT."""
        return self.put()

    @roles_required(['Super Admin', 'Alerts'])
    def delete(self):
        """Delete set alarm mail by truncating the file.

        Return 204 on success.
        """
        fd = open('/var/lib/box4s/alert_mail.conf', 'w')
        fd.close()
        return {}, 204


class APIUser(Resource):
    """BOX4s User Resource."""

    method_decorators = [login_required]

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()

    @roles_required(['Super Admin', 'User-Management'])
    def get(self, user_id):
        """Get a certain user and his information."""
        u = models.User.query.get(user_id)
        return models.USR.dump(u)

    def post(self, user_id):
        """Adding a User by POST not supported."""
        return {}, 501

    @roles_required(['Super Admin', 'User-Management'])
    def delete(self, user_id):
        """Delete User by ID.

        Perform checks:
        a) User must be Super Admin or User Manager
        b) User cannot delete himself
        c) Only Super Admins can delete Super Admin accounts
        """
        if current_user.id == user_id:
            abort(400, message="Users cannot delete their own accounts.")

        user = models.User.query.get(user_id)
        if user:
            # Current user is user management
            if models.Role.query.get(4) in current_user.roles:
                # role of the user to be deleted is superadmin
                if models.Role.query.get(1) in user.roles:
                    # dont allow deletion
                    abort(403, message="Only Super Admins can delete other Super Admin accounts.")

            if models.Role.query.get(1) in user.roles:
                # Trying to delete a Super Admin => current user has to be Super Admin
                if models.Role.query.get(1) not in current_user.roles:
                    abort(403, message="Only Super Admins can delete other Super Admin accounts.")

            db.session.delete(user)
            db.session.commit()
            return '', 204
        else:
            abort(404, message="User with ID {} not found. Nothing deleted.".format(user_id))

    @roles_required(['Super Admin', 'User-Management'])
    def put(self, user_id):
        """Update a user by ID."""
        self.parser.add_argument('email', type=str)
        self.parser.add_argument('first_name', type=str)
        self.parser.add_argument('last_name', type=str)
        self.parser.add_argument('active', type=bool)
        self.parser.add_argument('email_confirmed', type=bool)
        self.parser.add_argument('roles', type=int, action='append')

        try:
            self.args = self.parser.parse_args()
        except Exception:
            abort(400, message="Bad Request. Failed parsing arguments.")

        if not self.args['roles']:
            # Create empty array so checks work better
            self.args['roles'] = []

        if 1 in self.args['roles']:
            # Trying to set Super Admin
            # User has to be Super Admin himself
            if 'Super Admin' not in [a.name for a in current_user.roles]:
                # User is not Super admin
                abort(403, message="Not authorized to set Super Admin role.")
        elif user_id == current_user.id and 'Super Admin' in [a.name for a in current_user.roles]:
            # User is Super Admin
            # User tries to remove his Super Admin (may be by accident?)
            # Shouldn't be allowed, so we add it back to the array.
            self.args['roles'].append(1)

        user = models.User.query.get(user_id)
        if not user:
            abort(404, message="User with ID {} not found. Nothing changed.".format(user_id))
        user.email = self.args['email']
        user.first_name = self.args['first_name']
        user.last_name = self.args['last_name']
        user.roles = [models.Role.query.get(rid) for rid in self.args['roles']]
        # user.active = self.args['active']
        # Toggling active for now is disabled. We have a button for that
        # Else we have to work around administrators blocking themselves..
        if self.args['email_confirmed']:
            user.email_confirmed_at = datetime.now()
        else:
            user.email_confirmed_at = None
        try:
            db.session.add(user)
            db.session.commit()
        except Exception:
            abort(500, message="Error while saving user to database.")


class APIUserLock(Resource):
    """BOX4s User Lock Resource."""

    @roles_required(['Super Admin', 'User-Management'])
    def post(self, user_id):
        """Toggle User Lock status.

        Perform checks:
        a) User must be Super Admin or User Manager
        b) User cannot lock/unlock himself
        c) Only Super Admins can lock/unlock Super Admin accounts
        """
        user = models.User.query.get(user_id)
        if user:
            if current_user.id == user.id:
                # User is trying to disable himself => not allowed.
                abort(400, message="Users cannot lock/unlock their own accounts.")
            if models.Role.query.get(1) in user.roles:
                # User is trying to disable a Super Admin => he has to be Super Admin
                if models.Role.query.get(1) not in current_user.roles:
                    # He is not Super Admin
                    abort(403, message="Only Super Admins can lock/unlock Super Admin accounts.")

            # All checks passed => toggle active attribute
            user.active = not user.active
            db.session.add(user)
            db.session.commit()
            return {'user': user_id, 'active': user.active}, 200
        else:
            abort(404, message="User with ID {} not found. Nothing changed.".format(user_id))


class APISMTP(Resource):
    """Endpoint to interact with the SMTP config."""

    SMTP_MARSHAL = {
        'SMTP_HOST': fields.String,
        'SMTP_PORT': fields.Integer,
        'SMTP_USE_TLS': fields.Boolean,
        'SMTP_USERNAME': fields.String,
        'SMTP_SENDER_MAIL': fields.String,
    }

    def __init__(self):
        """Register Parser."""
        self.parser = reqparse.RequestParser()
        if not WizardMiddleware.isShowWizard():
            # If Wizard disabled, must have Super Admin or Config role and be authenticated
            if current_user.is_authenticated and current_user.has_role('Config'):
                # User is allowed to access, continue with resource.
                pass
            else:
                abort(403, message="Not allowed to access the SMTP endpoint.")

    def get(self):
        """Return the current SMTP configuration."""
        # Read current SMTP configuration from environment variables.
        config = {
            'SMTP_HOST': os.getenv('MAIL_SERVER'),
            'SMTP_PORT': os.getenv('MAIL_PORT'),
            'SMTP_USE_TLS': os.getenv('MAIL_USE_TLS'),
            'SMTP_USERNAME': os.getenv('MAIL_USERNAME'),
            'SMTP_SENDER_MAIL': os.getenv('MAIL_DEFAULT_SENDER'),
        }
        # marshal = apply described format
        return marshal(config, self.SMTP_MARSHAL), 200

    def post(self):
        """Set (replace) the SMTP configuration.

        Parameters:
            - senderName
            - senderMail
            - host
            - port
            - tls
            - username
            - password
        """
        # self.parser.add_argument('senderName', type=str)
        self.parser.add_argument('senderMail', type=str, required=True)
        self.parser.add_argument('host', type=str, required=True)
        self.parser.add_argument('port', type=int, required=True)
        self.parser.add_argument('tls', type=bool, required=True)
        self.parser.add_argument('username', type=str, required=True)
        self.parser.add_argument('password', type=str, required=True)
        self.args = self.parser.parse_args()
        writeSMTPConfig(self.args)
        restartBOX4s(sleep=5)
        return {"message": "SMTP config successfully updated."}, 200


class APISMTPCertificate(Resource):
    """Endpoint to interact with the SMTP certificate.

    POST accepts non-json form-data.
    """
    def __init__(self):
        if not WizardMiddleware.isShowWizard():
            # If Wizard disabled, must have Super Admin or Config role and be authenticated
            if current_user.is_authenticated and current_user.has_role('Config'):
                # User is allowed to access, continue with resource.
                pass
            else:
                abort(403, message="Not allowed to access the SMTP certificate endpoint.")

    def get(self):
        """Return not implemented."""
        abort(405, message="Certificate retrieval not implemented.")

    def post(self):
        """Replace the current SMTP certificate."""
        print(request.files)
        if 'cert' in request.files:
            file = request.files['cert']
            if file.filename == '':
                return {"message": "No SMTP Certificate supplied."}, 204
            file.save('/etc/ssl/certs/BOX4s-SMTP.pem')
            # Update update /etc/ssl/certs and ca-certificates.crt
            #  on docker host
            runHostCommand(cmd="sudo cp /etc/ssl/certs/BOX4s-SMTP.pem /usr/local/share/ca-certificates/BOX4s-SMTP.crt")
            runHostCommand(cmd="sudo update-ca-certificates")
            return {"message": "SMTP Certificate saved."}, 200
        else:
            return {"message": "No SMTP Certificate supplied."}, 204


class APIWizardReset(Resource):
    """Endpoint to reset the Wizard and start anew."""

    def get(self):
        """Return if a wizard reset should be available.

        Resetting is only allowed, if there exists one user AND this user's mail is not verified.
        200 => Allowed, 403 => Forbidden.
        """
        if models.User.query.count() == 1:
            user = models.User.query.first()
            if not user.email_confirmed_at:
                return {'message': 'Resetting Wizard allowed.'}, 200
        abort(403, message="Resetting Wizard not allowed at this stage.")

    def post(self):
        """Reset the Wizard and start anew.

        Resetting is only allowed, if there exists one user AND this user's mail is not verified (else return 403).
        Resetting is done by deleting this user, thus, wizard will start anew."""
        if models.User.query.count() == 1:
            user = models.User.query.first()
            if not user.email_confirmed_at:
                db.session.delete(user)
                db.session.commit()
                return {'message': 'success'}, 200
        abort(403, message="Resetting Wizard not allowed at this stage.")


class APIModules(Resource):
    """Endpoint to work with modules."""
    def get(self):
        """Get all modules and their state.
        Example: [{"name": "BOX4s_WAZUH", "enabled": "false"}, {"name": "BOX4s_INCMAN", "enabled": "false"}]
        """
        modules = []
        try:
            with open('/etc/box4s/modules.conf', 'r') as fm:
                for line in fm:
                    if not line.startswith('#'):
                        # not a comment
                        env = line.rstrip().split('=')
                        # module is the name before =
                        module = env[0]
                        state = env[1]
                        modules.append({'name': module, 'enabled': state})
        except Exception:
            abort(500, message="Failed to read the list of modules.")
        return modules, 200


class APIWazuhAgentPass(Resource):
    """Endpoint to interact with the Wazuh agent password."""
    def __init__(self):
        """Register Parser.

        Always abort if Wazuh module not enabled.
        """
        if not os.getenv('BOX4s_WAZUH') == 'true':
            abort(403, message="BOX4security is not configured to use Wazuh.")
        self.parser = reqparse.RequestParser()

    @roles_required(['Super Admin', 'Config'])
    def get(self):
        """GET the current wazuh agent password."""
        try:
            with open('/var/lib/box4s/wazuh-authd.pass', 'r') as f:
                password = f.read().strip()
            return {'password': password}
        except Exception:
            abort(500, message="Failed to read the Wazuh password file.")

    @roles_required(['Super Admin', 'Config'])
    def post(self):
        """Generate, set and return a new, random wazuh agent password."""
        password = helpers.generate_password()
        try:
            with open('/var/lib/box4s/wazuh-authd.pass', 'w') as f:
                f.write(password)
        except Exception:
            abort(500, message="Failed to write the Wazuh password file.")

        r = restartContainer('wazuh')
        if not r:
            abort(500, message="Failed to restart the Wazuh service.")
        return {'password': password}

    @roles_required(['Super Admin', 'Config'])
    def put(self):
        """Set the supplied password as wazuh agent password."""
        self.parser.add_argument('password', type=str, required=True)
        self.args = self.parser.parse_args()
        password = self.args['password']
        try:
            with open('/var/lib/box4s/wazuh-authd.pass', 'w') as f:
                f.write(password)
        except Exception:
            abort(500, message="Failed to write the Wazuh password file.")

        r = restartContainer('wazuh')
        if not r:
            abort(500, message="Failed to restart the Wazuh service.")
        return {'password': self.args['password']}


class Health(Resource):
    """Health endpoint."""

    def get(self):
        """Return Healthy."""
        return {'status': 'pass'}, 200


class NetworkAPI(Resource):
    """API resource for representing a single network."""

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()
        if not WizardMiddleware.isShowWizard():
            abort(503, message="The wizard and its API is not available.")

    def get(self, network_id):
        """Get a single network by id."""
        network = Network.query.get(network_id)
        if network:
            return NET.dump(network)
        else:
            abort(404, message="Network with ID {} not found.".format(network_id))

    def put(self, network_id):
        """Update a network by id."""
        self.parser.add_argument('name', type=str)
        self.parser.add_argument('ip_address', type=str)
        self.parser.add_argument('cidr', type=str)
        self.parser.add_argument('vlan', type=str)
        self.parser.add_argument('types', type=int, action='append')
        self.parser.add_argument('scancategory_id', type=int)
        self.parser.add_argument('scan_weekday', type=str)
        self.parser.add_argument('scan_time', type=str)

        try:
            self.args = self.parser.parse_args()
        except Exception:
            abort(400, message="Bad Request. Failed parsing arguments.")

        network = Network.query.get(network_id)
        if not network:
            abort(404, message="Network with ID {} not found. Nothing changed.".format(network_id))
        network.name = self.args['name']
        network.ip_address = self.args['ip_address']
        network.cidr = self.args['cidr']
        network.vlan = self.args['vlan']
        network.scancategory_id = self.args['scancategory_id']
        network.scan_weekday = self.args['scan_weekday']
        network.scan_time = self.args['scan_time']
        if self.args['types']:
            network.types = [NetworkType.query.get(tid) for tid in self.args['types']]
        else:
            network.types = []
        try:
            db.session.add(network)
            db.session.commit()
        except Exception:
            abort(500, message="Error while saving network to database.")

    def delete(self, network_id):
        """Delete a network by id."""
        network = Network.query.get(network_id)
        if network:
            db.session.delete(network)
            db.session.commit()
            return '', 204
        else:
            abort(404, message="Network with ID {} not found. Nothing deleted.".format(network_id))


class NetworksAPI(Resource):
    """API resource for representing multiple networks."""

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()
        if not WizardMiddleware.isShowWizard():
            abort(503, message="The wizard and its API is not available.")

    def get(self):
        networks = Network.query.all()
        return NETs.dump(networks)

    def post(self):
        """Create a new network and return its id."""
        pass

    def put(self):
        pass


class SystemAPI(Resource):
    """API resource for representing a single system."""

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()
        if not WizardMiddleware.isShowWizard():
            abort(503, message="The wizard and its API is not available.")

    def get(self, system_id):
        """Get a single system by id."""
        system = System.query.get(system_id)
        if system:
            return SYS.dump(system)
        else:
            abort(404, message="System with ID {} not found.".format(system_id))

    def put(self, system_id):
        """Update a system by id."""
        self.parser.add_argument('name', type=str)
        self.parser.add_argument('ip_address', type=str)
        self.parser.add_argument('location', type=str)
        self.parser.add_argument('scan_enabled', type=bool)
        self.parser.add_argument('ids_enabled', type=bool)
        self.parser.add_argument('types', type=int, action='append')
        self.parser.add_argument('network_id', type=int)

        try:
            self.args = self.parser.parse_args()
        except Exception:
            abort(400, message="Bad Request. Failed parsing arguments.")

        system = System.query.get(system_id)
        if not system:
            abort(404, message="System with ID {} not found. Nothing changed.".format(system_id))
        system.name = self.args['name']
        system.ip_address = self.args['ip_address']
        system.scan_enabled = self.args['scan_enabled']
        system.ids_enabled = self.args['ids_enabled']
        system.network_id = self.args['network_id']
        if self.args['types']:
            system.types = [SystemType.query.get(tid) for tid in self.args['types']]
        else:
            system.types = []
        try:
            db.session.add(system)
            db.session.commit()
        except Exception:
            abort(500, message="Error while saving system to database.")

    def delete(self, system_id):
        """Delete a system by id."""
        system = System.query.get(system_id)
        if system:
            db.session.delete(system)
            db.session.commit()
            return '', 204
        else:
            abort(404, message="System with ID {} not found. Nothing deleted.".format(system_id))


class SystemsAPI(Resource):
    """API resource for representing multiple systems."""

    def __init__(self):
        """Register Parser and argument for endpoint."""
        self.parser = reqparse.RequestParser()
        if not WizardMiddleware.isShowWizard():
            abort(503, message="The wizard and its API is not available.")

    def get(self):
        _systems = System.query.all()
        return SYSs.dump(_systems)

    def post(self):
        """Create a new system and return it."""
        self.parser.add_argument('name', type=str)
        self.parser.add_argument('ip_address', type=str)
        self.parser.add_argument('location', type=str)
        self.parser.add_argument('scan_enabled', type=bool)
        self.parser.add_argument('ids_enabled', type=bool)
        self.parser.add_argument('types', type=int, action='append')
        self.parser.add_argument('network_id', type=int)

        try:
            self.args = self.parser.parse_args()
        except Exception:
            abort(400, message="Bad Request. Failed parsing arguments.")

        newSystem = System()
        newSystem.name = self.args['name']
        newSystem.ip_address = self.args['ip_address']
        newSystem.scan_enabled = self.args['scan_enabled']
        newSystem.ids_enabled = self.args['ids_enabled']
        newSystem.network_id = self.args['network_id']
        if self.args['types']:
            newSystem.types = [SystemType.query.get(tid) for tid in self.args['types']]
        else:
            newSystem.types = []
        try:
            db.session.add(newSystem)
            db.session.commit()
            return SYS.dump(newSystem)
        except Exception:
            abort(500, message="Error while saving system to database.")

    def put(self):
        pass


class CertificateResource(Resource):
    """API resource for representing multiple systems."""

    def __init__(self):
        self.parse = reqparse.RequestParser()
        if not WizardMiddleware.isShowWizard():
            # If Wizard disabled, must have Super Admin or Config role and be authenticated
            if current_user.is_authenticated and current_user.has_role('Config'):
                # User is allowed to access, continue with resource.
                pass
            else:
                abort(403, message="Not allowed to access the certificate endpoint.")

    def get(self):
        """
        Return the currently installed HTTPS certificate.
        Private Key is NOT sent!
        """
        try:
            return send_file('/etc/nginx/certs/box4security.cert.pem', as_attachment=True)
        except Exception:
            abort(500, message="Failed sending the certificate.")

    def post(self):
        """
        Install a new HTTPS certificate (RSA) and its corresponding private key (RSA).
        """
        files = []
        try:
            files = request.files.getlist("files[]")
        except Exception:
            abort(400, message="Request does not contain files.")
        if not len(files) == 2:
            abort(400, message="Request does not contain two files.")
        validFiles = {'cert': None, 'key': None}
        for file in files:
            tempFile, tempFileName = tempfile.mkstemp(prefix='box4s_')
            os.close(tempFile)
            file.save(tempFileName)
            try:
                procOpensslCert = subprocess.Popen(['openssl', 'x509', '-inform', 'PEM', '-in', tempFileName, '-text', '-noout'], stdout=subprocess.PIPE, encoding="utf8")
                if procOpensslCert.wait() == 0:
                    # check returncode
                    # valid pem certificate!
                    validFiles['cert'] = file
                else:
                    # Not a valid certificate, try reading as key:
                    procOpensslKey = subprocess.Popen(['openssl', 'rsa', '-inform', 'PEM', '-in', tempFileName, '-noout'], stdout=subprocess.PIPE, encoding="utf8")
                    if procOpensslKey.wait() == 0:
                        # check return code
                        # valid key
                        validFiles['key'] = file
                    else:
                        os.remove(tempFileName)
                        abort(400, message="Supplied file is neither PEM RSA Private Key nor PEM x509 certificate.")
            except subprocess.SubprocessError:
                os.remove(tempFileName)
                abort(500, message="Failed parsing a file.")
            os.remove(tempFileName)
        if validFiles['cert'] and validFiles['key']:
            for f in validFiles.values():
                f.seek(0)
            validFiles['cert'].save('/etc/nginx/certs/box4security.cert.pem')
            validFiles['key'].save('/etc/nginx/certs/box4security.key.pem')
            # Restart BOX4s to apply changes.
            restartBOX4s(sleep=10)
            return {'message': 'Successfully updated key and certificate.'}, 200
        else:
            abort(400, message="Both files must be valid. Required: PEM RSA Private Key and PEM x509 certificate.")

    def put(self):
        """
        Replace the HTTPS certificate and its corresponding private key (same as POST).
        """
        return self.post()

    def delete(self):
        """
        Delete the currently installed HTTPS certificate and its private key.
        Generate a new random private key and a self-signed certificate.
        """
        abort(405, message="Automatic (re)-creation not implemented yet.")
