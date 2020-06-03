"""Module to handle all webapp routes."""
from source import app, mail, db, userman
from source.api import BPF, BPFs, LSR, LSRs, Version, AvailableReleases, LaunchUpdate, UpdateLog, UpdateStatus, Health, APIUser, APIUserLock, Alerts, Alert
from source.models import User, Role
from source.config import Dashboards
import source.error
from flask_restful import Api
from flask import render_template, send_from_directory, request, abort, send_file, Response
from flask_user import login_required, current_user, roles_required
from flask_mail import Message
from source.forms import AddUserForm
import os
import re
import string
import secrets


def generate_password():
    """Generate a ten-character alphanumeric password.

    with at least one lowercase character,
    at least one uppercase character,
    and at least three digits
    See: https://docs.python.org/3/library/secrets.html#recipes-and-best-practices
    """
    alphabet = string.ascii_letters + string.digits
    while True:
        password = ''.join(secrets.choice(alphabet) for i in range(10))
        if (any(c.islower() for c in password) and any(c.isupper() for c in password) and sum(c.isdigit() for c in password) >= 3):
            break
    return password


api = Api(app)

api.add_resource(BPF, '/rules/bpf/<int:rule_id>')
api.add_resource(BPFs, '/rules/bpf/')
api.add_resource(LSR, '/rules/logstash/<int:rule_id>')
api.add_resource(LSRs, '/rules/logstash/')
api.add_resource(Version, '/ver/')
api.add_resource(AvailableReleases, '/ver/releases/')
api.add_resource(LaunchUpdate, '/update/launch/')
api.add_resource(UpdateLog, '/update/log/')
api.add_resource(UpdateStatus, '/update/status/')
api.add_resource(Health, '/_health')
api.add_resource(APIUser, '/api/user/<int:user_id>')
api.add_resource(APIUserLock, '/api/user/<int:user_id>/lock')
api.add_resource(Alert, '/rules/alerts/<int:alert_id>')
api.add_resource(Alerts, '/rules/alerts/')


@app.route('/')
@login_required
def index():
    """Return the start dashboard."""
    return catchall('start')


@app.route("/static/<path:filename>")
@login_required
def staticfiles(filename):
    """Return a static file."""
    return send_from_directory(app.config["STATIC_FOLDER"], filename)


@app.route('/faq', methods=['GET'])
@login_required
@roles_required(['Super Admin', 'FAQ'])
def faq():
    """Return the FAQ page.

    Required Role: FAQ OR Super Admin
    Environment variable KUNDE is the client company name and set to Standard if not existent.
    The value is displayed in the contact form.
    """
    client = os.getenv('KUNDE')
    return render_template('faq.html', client=client)


@app.route('/super admin')
@app.route('/user-management')
@app.route('/user', methods=['GET', 'POST'])
@login_required
@roles_required(['Super Admin', 'User-Management'])
def user():
    """Display the user admin page.

    Required Role: User-Management OR Super Admin
    `create` will open the modal to add a user immediately.
    """
    create = False
    adduser = AddUserForm(request.form)
    adduser.roles.choices = [(r.id, r.description) for r in Role.query.order_by('id')]
    if request.method == 'POST' and adduser.validate():
        user = User()
        adduser.populate_obj(user)  # Copies matching attributes from form onto user
        user.roles = [Role.query.get(rid) for rid in user.roles]  # Get actual role objects from their IDs
        rndpass = generate_password()
        hash = userman.hash_password(rndpass)
        user.password = hash
        db.session.add(user)
        db.session.commit()
        try:
            userman.email_manager._render_and_send_email(user.email, user, userman.USER_INVITE_USER_EMAIL_TEMPLATE, user_pass=rndpass)
            if adduser.email_copy.data:
                userman.email_manager._render_and_send_email(current_user.email, user, userman.USER_INVITE_USER_EMAIL_TEMPLATE, user_pass=rndpass)
            # send confirmation E-Mail
            userman.email_manager.send_confirm_email_email(user, None)
        except Exception:
            # delete new User object if send fails
            userman.db_manager.delete_object(user)
            userman.db_manager.commit()
            raise
    elif request.method == 'POST':
        create = True
    users = User.query.order_by(User.id.asc()).all()
    return render_template('user.html', users=users, userform=adduser, create=create)


@app.route('/faq', methods=['POST'])
@login_required
@roles_required(['Super Admin', 'FAQ'])
def faq_mail():
    """Handle the submitted contanct form and send via email.

    Environment variable KUNDE is the client company name.
    If there is no $KUNDE variable it is shown to the value from the user form.
    If even there it is not defined it is set to "Undefinierter Kunde" for the email.
    The value is displayed in the contact form.

    The E-Mail is sent to a MS Teams Channel: 0972f9a3.4sconsult.de@emea.teams.ms
    """
    client = os.getenv('KUNDE')
    if not client:
        client = request.values.get('company', 'Undefinierter Kunde')

    # Build a subject or set default one of none given
    subject = "[{}] {}".format(client, request.values.get('subject') or 'BOX4Security FAQ-Kontaktformular')

    # Build the body
    body = """
        Kunde: {}
        Kontakt: {}
        {}
        """.format(client, request.values.get('email'), request.values.get('body'))

    # Build Message, and render view with sent confirmation
    msg = Message(subject=subject, recipients=['0972f9a3.4sconsult.de@emea.teams.ms'], body=body)
    msg.msgId = msg.msgId.split('@')[0] + '@4sconsult.de'  # shorter msgID so microsoft likes it
    mail.send(msg)
    client = os.getenv('KUNDE', '')  # Reset client variable
    return render_template('faq.html', client=client, mailsent=True)


@app.route('/updates')
@app.route('/update', methods=['GET'])
@login_required
@roles_required(['Super Admin', 'Updates'])
def update():
    """Return the update page."""
    return render_template("update.html")


@app.route('/update', methods=['POST'])
@login_required
@roles_required(['Super Admin', 'Updates'])
def update_post():
    """Return the update page."""
    return render_template("update.html")


@app.route('/filter', methods=['GET'])
@login_required
@roles_required(['Super Admin', 'Filter'])
def rules():
    """Return the filter page."""
    return render_template("filter.html")


@app.route('/update/log/download', methods=['GET'])
@login_required
@roles_required(['Super Admin', 'Updates'])
def updatelogdl():
    """Try to downlaod the update.log."""
    try:
        return send_file('/var/log/box4s/update.log', as_attachment=True, attachment_filename='update.log', mimetype='text/plain')
    except Exception:
        return "", 501


@app.route('/docs', methods=['GET'])
@login_required
@roles_required(['Super Admin', 'Wiki'])
def wiki_index():
    """Show wiki index."""
    return render_template('docs.html', docs_url="/wiki/gollum/overview")


@app.route('/auth')
def authenticate():
    """Authenticate against the webapp."""
    original_uri = request.headers.get('X-Original-URI')
    # Check if user is authenticated and active:
    if current_user.is_authenticated:
        if not current_user.active:
            abort(403)
        # Perform regex matching on the original url to determine resource:
        if re.match(r'^/kibana.*$', original_uri):
            # URI starts with /kibana
            # Check if this is a dashboard queried or another resource:
            dashboard = list(filter(lambda d: d.url == original_uri, Dashboards))
            if dashboard:
                # Since dashboard urls are unique
                # this is a list of 1 item so we make it an object
                dashboard = dashboard[0]
                # Check if current user is permitted
                if not set(['Super Admin', 'Dashboards-Master', dashboard.role]).isdisjoint([a.name for a in current_user.roles]):
                    # User is Super Admin or has the required dashboard role
                    return "", 200
                else:
                    # User is not permitted to see request this dashbaord
                    abort(403)
            else:
                # Another resource, allow.
                # Allow Super Admins
                if "Super Admin" in [a.name for a in current_user.roles]:
                    return "", 200
                # Allow any other Dashboard Role
                elif not set(['Startseite', 'Dashboards-Master', 'SIEM', 'Schwachstellen', 'Netzwerk']).isdisjoint([a.name for a in current_user.roles]):
                    return "", 200
                # Requirements not met => Deny.
                else:
                    abort(403)
        elif re.match(r'^/(docs|wiki).*$', original_uri):
            if not set(['Super Admin', 'Wiki']).isdisjoint([a.name for a in current_user.roles]):
                # User is Super Admin or has the Wiki role
                resp = Response("")
                resp.headers['X-Auth-Username'] = current_user.getName()
                return resp
            else:
                # User is not permitted to request the Wiki
                abort(403)
    else:
        abort(401)


# must be the last one (catchall)
# let variable r hold the path
# Redirects for permission pages from 403
@app.route('/dashboards-master', defaults={'r': 'start'})
@app.route('/schwachstellen', defaults={'r': 'vuln-overview'})
@app.route('/siem', defaults={'r': 'siem-overview'})
@app.route('/netzwerk', defaults={'r': 'network-overview'})
@app.route('/startseite', defaults={'r': 'start'})
@app.route('/<path:r>')
@login_required
def catchall(r):
    """Render a route not caught before."""
    dashboard = list(filter(lambda d: d.name == r, Dashboards))
    # if requested resource exists
    if dashboard:
        # Since dashboard names are unique
        # this is a list of 1 item so we make it an object
        dashboard = dashboard[0]
        if not set(['Super Admin', 'Dashboards-Master', dashboard.role]).isdisjoint([a.name for a in current_user.roles]):
            # User is Super Admin or has the required dashboard role
            return render_template('dashboard.html', dashboard=dashboard)
        else:
            # not permitted!
            abort(403)
    else:
        abort(404)
