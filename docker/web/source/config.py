import os
SQL_VERBOSE = False


class Config(object):
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL", "sqlite://")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    STATIC_FOLDER = f"{os.getenv('APP_FOLDER')}/project/static"

    # Mail
    MAIL_SERVER = os.getenv("MAIL_SERVER")
    MAIL_PORT = os.getenv("MAIL_PORT")
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS")
    MAIL_USERNAME = os.getenv("MAIL_USERNAME")
    MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
    MAIL_DEFAULT_SENDER = os.getenv("MAIL_DEFAULT_SENDER")


class Dashboard():
    url = None
    name = None
    parent_id = None

    def __init__(self, url="", name="", parent_id=""):
        self.url = url
        self.name = name
        self.parent_id = parent_id


Dashboards = [
    Dashboard(name='start', url='/kibana/app/kibana#/dashboard/8d13ea50-3de1-11ea-bbd4-bb7e0278945f?_g=()&_a=(fullScreenMode:!t)', parent_id='#start'),
    Dashboard(name='siem-overview', url='/kibana/app/kibana#/dashboard/90203990-3dd9-11ea-bbd4-bb7e0278945f?_g=()&_a=(fullScreenMode:!t)', parent_id='#siem'),
    Dashboard(name='siem-alerts', url='/kibana/app/kibana#/dashboard/a7bfd050-ce1d-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#siem'),
    Dashboard(name='siem-asn', url='/kibana/app/kibana#/dashboard/9391fd20-ce4e-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#siem'),
    Dashboard(name='siem-http', url='/kibana/app/kibana#/dashboard/691ea410-cee1-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#siem'),
    Dashboard(name='siem-dns', url='/kibana/app/kibana#/dashboard/1d109db0-ceed-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#siem'),
    Dashboard(name='siem-proto', url='/kibana/app/kibana#/dashboard/f4ad4f80-ce38-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#siem'),
    Dashboard(name='vuln-overview', url='/kibana/app/kibana#/dashboard/140fb900-6e82-11ea-84ea-3b1a8de87e76?_g=()&_a=(fullScreenMode:!t)', parent_id='#vuln'),
    Dashboard(name='vuln-progress', url='/kibana/app/kibana#/dashboard/f8712020-cefa-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#vuln'),
    Dashboard(name='vuln-details', url='/kibana/app/kibana#/dashboard/39c6fc40-6e81-11ea-84ea-3b1a8de87e76?_g=()&_a=(fullScreenMode:!t)', parent_id='#vuln'),
    Dashboard(name='network-overview', url='/kibana/app/kibana#/dashboard/dc847fd0-3dd9-11ea-bbd4-bb7e0278945f?_g=()&_a=(fullScreenMode:!t)', parent_id='#net'),
    Dashboard(name='network-streams', url='/kibana/app/kibana#/dashboard/e5fbd440-ce2c-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#net'),
    Dashboard(name='network-asn', url='/kibana/app/kibana#/dashboard/c2b4c450-ce46-11e9-943f-fdbfa2556276?_g=()&_a=(fullScreenMode:!t)', parent_id='#net')
]
