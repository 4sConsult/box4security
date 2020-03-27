from source import app, mail
from source.api import BPF, BPFs, LSR, LSRs, Alert, Version, AvailableReleases, LaunchUpdate, UpdateLog, UpdateStatus
from source.config import Dashboards
from flask_restful import Api
from flask import render_template, send_from_directory, request, redirect, url_for, abort, send_file
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


@app.route('/')
def index():
    return catchall('start')


@app.route("/static/<path:filename>")
def staticfiles(filename):
    return send_from_directory(app.config["STATIC_FOLDER"], filename)


@app.route('/faq', methods=['GET'])
def faq():
    client = os.getenv('KUNDE', 'Standard')
    return render_template('faq.html', client=client)


@app.route('/faq', methods=['POST'])
def faq_mail():
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
    return render_template("update.html")


@app.route('/update', methods=['POST'])
def update_post():
    return render_template("update.html")


@app.route('/filter', methods=['GET'])
def rules():
    return render_template("filter.html")


@app.route('/update/log/download', methods=['GET'])
def updatelogdl():
    try:
        return send_file('/var/log/box4s/update.log')
    except Exception:
        return "", 501


# must be the last one (catchall)
# let variable r hold the path
@app.route('/<path:r>')
def catchall(r):
    dashboard = list(filter(lambda d: d.name == r, Dashboards))
    # if requested resource exists
    if dashboard:
        # Since dashboard names are unique
        # this is a list of 1 item so we make it an object
        dashboard = dashboard[0]
        return render_template('dashboard.html', dashboard=dashboard)
    else:
        abort(404)
