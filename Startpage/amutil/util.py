import os
import tempfile
import shutil
import git


def getEnv():
    try:
        env = {'GITDIR': os.environ['GITDIR'].lstrip(os.path.sep), 'BASEDIR': os.environ['BASEDIR']}
    except KeyError as e:
        env = {}
    return env


def toggleSQL():
    # Pipelines.yml
    new, new_path = tempfile.mkstemp(text=True)
    with open('/etc/logstash/pipelines.yml', 'r') as pipeyml:
        with open(new, 'w') as new_f:
            for line in pipeyml:
                # Requires sqltransfer to be in both lines (- pipeline.id AND path.config)
                if "sqltransfer" in line:
                    if line.lstrip().startswith('#'):
                        new_f.write(line.replace('#', ''))
                    else:
                        new_f.write('#'+line)
                else:
                    new_f.write(line)
            new_f.seek(0)
            shutil.copy(new_path, '/etc/logstash/pipelines.yml')
    os.remove(new_path)
    # Traverse conf.d directory and enable sqloutput
    for root, dirs, files in os.walk('/etc/logstash/conf.d'):
        for f in files:
            if f.startswith('100_'):
                # open 100-output files
                new, new_path = tempfile.mkstemp(text=True)
                with open(new, 'w') as new_f:
                    with open(os.path.join(root, f), 'r') as conf:
                        for line in conf:
                            if "sqloutput" in line:
                                if line.lstrip().startswith('#'):
                                    new_f.write(line.lstrip().replace('#', ''))
                                else:
                                    new_f.write('#'+line)
                            else:
                                new_f.write(line)
                    new_f.seek(0)
                    shutil.copy(new_path, os.path.join(root, f))
                os.remove(new_path)


def updateRepo():
    e = getEnv()
    if not e:
        return "Environment variables not set"
    g = git.cmd.Git(working_dir=os.path.join(e['BASEDIR'], e['GITDIR']))
    return g.pull()


def whatBranch():
    e = getEnv()
    if not e:
        return "Environment variables not set"
    repo = git.Repo(path=os.path.join(e['BASEDIR'], e['GITDIR']))
    return repo.active_branch.name


def allBranches():
    e = getEnv()
    if not e:
        return ["Environment variables not set"]
    repo = git.Repo(path=os.path.join(e['BASEDIR'], e['GITDIR']))
    return [h.name for h in repo.heads]
