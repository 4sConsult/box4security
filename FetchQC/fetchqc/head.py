import json
from . import models, db, auth
from sqlalchemy import text


class __jsonRepr__(object):
    def __repr__(self):
        return json.dumps(self.__dict__)


class Connection(__jsonRepr__):
    def __init__(self):
        self.host = "it-security.am-gmbh.de"
        self.quickcheck_id = None
        self.user = None
        self.token = None

    def __repr__(self):
        return json.dumps(self.__dict__)


def run():
    auth.drop_privileges()
    conn = Connection()
    credentials(conn)
    (networks, systems) = fetch(conn)


def credentials(conn):
    print('Enter host or press ENTER to use {}'.format(conn.host))
    host = input()
    if host:
        conn.host = host
    while not conn.quickcheck_id:
        print('Enter Quickcheck-ID:')
        conn.quickcheck_id = input()
    while not conn.user:
        print('Please enter your username (ITS-Plattform): ')
        conn.user = input()
    while not conn.token:
        print('Get your token from https://{}/users/settings/'.format(conn.host))
        print('Please enter the API-Token for {}'.format(conn.user))
        conn.token = input()
    print("\nEverthing ok? (Press ENTER to continue)")
    print(conn)
    input()


def fetch(conn):
    import requests
    url = 'http://' + conn.host + '/api/'
    print("Base-URL: {}".format(url))
    headers = {'X-AM-API_USER': conn.user, 'X-AM-API_TOKEN': conn.token}

    print("Fetching Networks")
    resp = requests.get(url=url + "quickchecks/{}/networks".format(conn.quickcheck_id), headers=headers)
    if resp.status_code is requests.codes.ok:
        resp_nets = resp.json()['response']
    else:
        resp.raise_for_status()
        exit()

    print("Received Networks")
    networks = []
    for net in resp_nets:
        instance = db.session.query(models.Network).filter(models.Network.ip == net['ip']).first()
        if not instance:
            instance = models.Network._fromdict(net)
            db.session.add(instance)
        networks.append(instance)
        db.session.commit()
        print(networks[-1])

    print("Fetching Systems")
    resp = requests.get(url=url + "quickchecks/{}/systems".format(conn.quickcheck_id), headers=headers)
    if resp.status_code is requests.codes.ok:
        resp_syss = resp.json()['response']
    else:
        resp.raise_for_status()
        exit()

    print("Received Systems")
    systems = []
    for sys in resp_syss:
        system_instance = db.session.query(models.System).filter(models.System.ip == sys['ip']).first()
        if system_instance:
            continue
        system_instance = models.System._fromdict(sys)
        system_instance.types = []
        types = []
        for type in sys['types']:
            # hack to rename Quickcheck-System (ITS-Plattform) to BOX4security
            type = 'BOX4security' if type == 'Quickcheck-System' else type
            instance = db.session.query(models.SystemType).filter(models.SystemType.name == type).scalar()
            if not instance:
                instance = models.SystemType(name=type)
                db.session.add(instance)
            types.append(instance)
        db.session.commit()
        system_instance.types = types
        db.session.add(system_instance)
        systems.append(system_instance)
        print(systems[-1])
    db.session.commit()

    branch = db.session.query(models.Branch).filter(models.Branch.bicompanyid == conn.quickcheck_id).first()
    if not branch:
        print("Enter a company/branch name:")
        branch = models.Branch(bicompanyid=conn.quickcheck_id)
        branch.name = input()
        print("Writing Company and Branch info")
        db.session.add(branch)
        db.session.commit()

    return networks, systems


if __name__ == '__main__':
    run()
