from app import app
from flask import render_template, redirect, Response, url_for, request
import subprocess
import os
from amutil import services as util_serv
from amutil import util
import time
import git



@app.route('/')
def startpage():
    env = util.getEnv()
    services = {}
    for s in util_serv.SERVICES:
        services[s] = util_serv.getServiceState(s)
    pipes = util_serv.getLogstashPipes()
    branch = util.whatBranch()
    branches = util.allBranches()
    return render_template('index.html', env=env, services=services, pipelines=pipes, branch=branch, branches=branches)


@app.route('/api/clean_system')
def clean_system():
    env = util.getEnv()
    if env:
        def inner():
            p = subprocess.Popen(
                ['sudo', os.path.join(env['BASEDIR'], env['GITDIR'], 'Scripts', 'System_Scripts', 'clean_system.sh'),
                    '--bitte-reinigen'],
                shell=False,
                universal_newlines=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT)
            for stdout_line in iter(p.stdout.readline, ""):
                yield stdout_line.rstrip() + '<br/>\n'
            p.stdout.close()
        return Response(inner(), mimetype='text/html')


@app.route('/api/toggle_sql_output')
def toggle_sql():
    util.toggleSQL()
    return redirect(url_for("startpage"))


@app.route('/api/startstop/<param>')
def startstop(param):
    if param not in ['start', 'stop']:
        return Response(response='Param must be start/stop', status=400)
    for s in util_serv.SERVICES:
        util_serv.changeServiceState(name=s, state=param)
    return redirect(url_for("startpage"))


@app.route('/api/update_repo')
def update_repo():
    git_msg = util.updateRepo()
    return Response(response=git_msg, mimetype='text/plain')


@app.route('/api/switchbranch')
def switchbranch():
    if request.method == 'GET' and request.args.get('branch'):
        e = util.getEnv()
        if not e:
            return Response("Environment variables not set")
        repo = git.Repo(path=os.path.join(e['BASEDIR'], e['GITDIR']))
        try:
            repo.git.checkout(request.args.get('branch'))
        except git.exc.GitCommandError as e:
            return Response("Could not switch branch<br>"+e.stderr, mimetype='text/html')
    return redirect(url_for('startpage'))


@app.route('/api/deploy')
def deploy():
    env = util.getEnv()
    if env:
        def inner():
            p = subprocess.Popen([
                os.path.join(env['BASEDIR'], env['GITDIR'], 'Scripts', 'System_Scripts', 'deploy.sh')],
                shell=False,
                universal_newlines=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT)
            for stdout_line in iter(p.stdout.readline, ""):
                yield stdout_line.rstrip() + '<br/>\n'
            p.stdout.close()
        return Response(inner(), mimetype='text/html')


if __name__ == '__main__':
    app.run()
