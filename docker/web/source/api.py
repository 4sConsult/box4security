"""Module for webapp API."""
from source import models, db
from flask_restful import Resource, reqparse, abort
from flask_user import login_required, current_user, roles_required
from flask import request, render_template
import requests
import os
import subprocess
import json
from requests.exceptions import Timeout, ConnectionError
from datetime import datetime


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
        # read pw from $SSHPASS and login to dockerhost to execute restartSuricata
        os.system('sshpass -e ssh -o StrictHostKeyChecking=no amadmin@dockerhost sudo /home/amadmin/restartSuricata.sh')


def writeAlertFile(alert):
    """Write an alert dict to file."""
    # TODO: check permissions / Try error
    with open(f'/var/lib/elastalert/rules/{ alert["safe_name"] }.yaml', 'w') as f_alert:
        filled = render_template(f'application/{ alert["type"] }.yaml.j2', alert=alert)
        f_alert.write(filled)


def writeQuickAlertFile(key):
    """Write a quick alert to file."""
    # TODO: check permissions / Try error
    with open(f'/var/lib/elastalert/rules/quick_{ key }.yaml', 'w') as f_alert:
        filled = render_template(f'application/quick_alert_{ key }.yaml.j2', alert={})
        f_alert.write(filled)


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

        version is a semantic version string
        env specifies the environment: prod (default) or dev
        """
        CURRVER = os.getenv('VERSION')
        return {'version': CURRVER, 'env': os.getenv('BOX4s_ENV', 'production')}


class AvailableReleases(Resource):
    """API Resource for working with all available releases."""

    def get(self):
        """GET: fetch and return all available releases with their relevant info from GitLab."""
        try:
            git = requests.get('https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags',
                               headers={'PRIVATE-TOKEN': os.getenv('GIT_TOKEN')}).json()
        except Timeout:
            abort(504, message="GitLab API Timeout")
        except ConnectionError:
            abort(503, message="GitLab API unreachable")
        except Exception:
            abort(502, message="GitLab API Failure")
        else:
            # take only relevant info
            res = [{'version': tag['name'], 'message': tag['message'], 'date': tag['commit']['created_at'], 'changelog': tag['release']['description'] if tag['release'] else ''} for tag in git]
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
        subprocess.Popen('sshpass -e ssh -o StrictHostKeyChecking=no amadmin@dockerhost sudo /home/amadmin/box4s/main/update.sh', shell=True)
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

    def get(self):
        """Get update status."""
        with open('/var/lib/box4s/.update.state', 'r') as f:
            # Remove whitespaces and newlines from line
            status = f.readline().strip().rstrip()
            return {'status': status}, 200

    def post(self):
        """Set new update status."""
        self.parser.add_argument('status', type=str)
        self.args = self.parser.parse_args()
        with open('/var/lib/box4s/.update.state', 'w') as f:
            f.write(self.args['status'])
            return {}, 200

    def delete(self):
        """Empty update state file."""
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
        return requests.get(f"http://elastalert:3030/rules/{alert_id}")

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
        try:
            self.args = self.parser.parse_args()
        except Exception:
            abort(400, message="Bad Request. Failed parsing arguments.")

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
        # writeQuickAlertFile(self.args['key'])
        yaml = render_template(f"application/quick_alert_{  self.args['key'] }.yaml.j2", alert={})
        response = requests.post(f"http://elastalert:3030/rules/quick_{  self.args['key'] }", json={'yaml': yaml})
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
        # os.remove(f'/var/lib/elastalert/rules/quick_{ self.args["key"] }.yaml')
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


class Health(Resource):
    """Health endpoint."""

    def get(self):
        """Return Healthy."""
        return {'status': 'pass'}, 200
