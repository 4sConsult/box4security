from source import app, mail
from source.api import BPF, BPFs, LSR, LSRs, Alert, Version, AvailableReleases, LaunchUpdate, UpdateLog, UpdateStatus, Health
from source.config import Dashboards
from flask_restful import Api
from flask import render_template, send_from_directory, request, redirect, url_for, abort, send_file
from flask_user import login_required
from flask_mail import Message
import os

api = Api(app)

api.add_resource(BPF, '/rules/bpf/<int:rule_id>')
api.add_resource(BPFs, '/rules/bpf/')
api.add_resource(LSR, '/rules/logstash/<int:rule_id>')
api.add_resource(LSRs, '/rules/logstash/')
api.add_resource(Alert, '/alert/<int:alert_id>')
api.add_resource(Version, '/ver/')
api.add_resource(AvailableReleases, '/ver/releases/')
api.add_resource(LaunchUpdate, '/update/launch/')
api.add_resource(UpdateLog, '/update/log/')
api.add_resource(UpdateStatus, '/update/status/')
api.add_resource(Health, '/_health')


@app.route('/')
def index():
    """Return the start dashboard."""
    return catchall('start')


@app.route("/static/<path:filename>")
def staticfiles(filename):
    """Return a static file."""
    return send_from_directory(app.config["STATIC_FOLDER"], filename)


@app.route('/faq', methods=['GET'])
@login_required
def faq():
    """Return the FAQ page.

    Environment variable KUNDE is the client company name and set to Standard if not existent.
    The value is displayed in the contact form.
    """
    client = os.getenv('KUNDE', 'Standard')
    return render_template('faq.html', client=client)


@app.route('/faq', methods=['POST'])
@login_required
def faq_mail():
    """Handle the submitted contanct form and send via email.

    Environment variable KUNDE is the client company name and set to Standard if not existent.
    The value is displayed in the contact form.

    The E-Mail is sent to a MS Teams Channel: 0972f9a3.4sconsult.de@emea.teams.ms
    """
    client = os.getenv('KUNDE', 'Default-Kunde')

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

    return render_template('faq.html', client=client, mailsent=True)


@app.route('/update', methods=['GET'])
def update():
    """Return the update page."""
    return render_template("update.html")


@app.route('/update', methods=['POST'])
def update_post():
    """Return the update page."""
    return render_template("update.html")


@app.route('/filter', methods=['GET'])
def rules():
    """Return the filter page."""
    return render_template("filter.html")


@app.route('/update/log/download', methods=['GET'])
def updatelogdl():
    """Try to downlaod the update.log."""
    try:
        return send_file('/var/log/box4s/update.log', as_attachment=True, attachment_filename='update.log', mimetype='text/plain')
    except Exception:
        return "", 501


# must be the last one (catchall)
# let variable r hold the path
@app.route('/<path:r>')
def catchall(r):
    """Render a route not caught before."""
    dashboard = list(filter(lambda d: d.name == r, Dashboards))
    # if requested resource exists
    if dashboard:
        # Since dashboard names are unique
        # this is a list of 1 item so we make it an object
        dashboard = dashboard[0]
        return render_template('dashboard.html', dashboard=dashboard)
    else:
        abort(404)
