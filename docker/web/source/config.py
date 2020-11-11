"""Module handling webapp config."""
import os
SQL_VERBOSE = False


class Config():
    """Config class for the Flask webapp."""

    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL", "sqlite://")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    STATIC_FOLDER = "{}/project/static".format(os.getenv('APP_FOLDER'))
    WAZUH_FOLDER = "{}/source/wazuh".format(os.getenv('APP_FOLDER'))

    SECRET_KEY = os.getenv("SECRET_KEY")
    SESSION_COOKIE_SECURE = True
    REMEMBER_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    REMEMBER_COOKIE_HTTPONLY = True

    # representation name
    USER_APP_NAME = "BOX4security"
    USER_ENABLE_CONFIRM_EMAIL = True
    USER_ALLOW_LOGIN_WITHOUT_CONFIRMED_EMAIL = False
    # Allow logins by username
    USER_ENABLE_USERNAME = False
    USER_REQUIRE_INVITATION = False
    USER_AUTO_LOGIN_AFTER_CONFIRM = False
    USER_UNAUTHORIZED_ENDPOINT = 'forbidden'
    USER_AFTER_LOGIN_ENDPOINT = ''

    # View Templates
    USER_REGISTER_TEMPLATE = 'user/register.html'
    USER_LOGIN_TEMPLATE = 'user/login.html'
    USER_RESET_PASSWORD_TEMPLATE = 'user/reset_password.html'
    USER_FORGOT_PASSWORD_TEMPLATE = 'user/forgot_password.html'
    USER_CHANGE_PASSWORD_TEMPLATE = 'user/change_password.html'
    USER_RESEND_CONFIRM_EMAIL_TEMPLATE = 'user/resend_confirm_email.html'

    # E-Mail templates
    USER_CONFIRM_EMAIL_TEMPLATE = 'user/emails/confirm_email'
    USER_INVITE_USER_EMAIL_TEMPLATE = 'user/emails/invite_user'
    USER_PASSWORD_CHANGED_EMAIL_TEMPLATE = 'user/emails/password_changed'
    USER_REGISTERED_EMAIL_TEMPLATE = 'user/emails/registered'
    USER_RESET_PASSWORD_EMAIL_TEMPLATE = 'user/emails/reset_password'
    USER_USERNAME_CHANGED_EMAIL_TEMPLATE = 'user/emails/username_changed'

    # Mail
    MAIL_SERVER = os.getenv("MAIL_SERVER")
    MAIL_PORT = os.getenv("MAIL_PORT")
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS")
    MAIL_USERNAME = os.getenv("MAIL_USERNAME")
    MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
    MAIL_DEFAULT_SENDER = os.getenv("MAIL_DEFAULT_SENDER")


class Dashboard():
    """Class representation of a Dashboard."""

    url = None
    name = None
    parent_id = None
    role = None

    def __init__(self, url="", name="", parent_id="", role=""):
        """Construct with URL, name and parent."""
        self.url = url
        self.name = name
        self.parent_id = parent_id
        self.role = role


Dashboards = [
    Dashboard(name='start', url='/kibana/app/kibana#/dashboard/8d13ea50-3de1-11ea-bbd4-bb7e0278945f?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#start', role='Startseite'),
    Dashboard(name='siem-overview', url='/kibana/app/kibana#/dashboard/90203990-3dd9-11ea-bbd4-bb7e0278945f?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#siem', role='SIEM'),
    Dashboard(name='siem-alerts', url='/kibana/app/kibana#/dashboard/a7bfd050-ce1d-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#siem', role='SIEM'),
    Dashboard(name='siem-asn', url='/kibana/app/kibana#/dashboard/9391fd20-ce4e-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#siem', role='SIEM'),
    Dashboard(name='siem-http', url='/kibana/app/kibana#/dashboard/691ea410-cee1-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#siem', role='SIEM'),
    Dashboard(name='siem-dns', url='/kibana/app/kibana#/dashboard/1d109db0-ceed-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#siem', role='SIEM'),
    Dashboard(name='siem-proto', url='/kibana/app/kibana#/dashboard/f4ad4f80-ce38-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#siem', role='SIEM'),
    Dashboard(name='siem-discover', url='/kibana/app/discover#/?embed=true', parent_id='#siem', role='Config'),
    Dashboard(name='siem-social-media', url='/kibana/app/kibana#/dashboard/bf5a8370-7031-11ea-93fd-e12e440dc7e1?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now%2Fd,to:now%2Fd))', parent_id='#siem', role='SIEM'),
    Dashboard(name='vuln-overview', url='/kibana/app/kibana#/dashboard/140fb900-6e82-11ea-84ea-3b1a8de87e76?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30d,to:now))', parent_id='#vuln', role='Schwachstellen'),
    Dashboard(name='vuln-progress', url='/kibana/app/kibana#/dashboard/f8712020-cefa-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-90d,to:now))', parent_id='#vuln', role='Schwachstellen'),
    Dashboard(name='vuln-details', url='/kibana/app/kibana#/dashboard/39c6fc40-6e81-11ea-84ea-3b1a8de87e76?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30d,to:now))', parent_id='#vuln', role='Schwachstellen'),
    Dashboard(name='network-overview', url='/kibana/app/kibana#/dashboard/dc847fd0-3dd9-11ea-bbd4-bb7e0278945f?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30d,to:now))', parent_id='#net', role='Netzwerk'),
    Dashboard(name='network-streams', url='/kibana/app/kibana#/dashboard/e5fbd440-ce2c-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30d,to:now))', parent_id='#net', role='Netzwerk'),
    Dashboard(name='network-asn', url='/kibana/app/kibana#/dashboard/c2b4c450-ce46-11e9-943f-fdbfa2556276?embed=true&_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30d,to:now))', parent_id='#net', role='Netzwerk'),
]

# Enable Wazuh Dashboard only, if module is active
try:
    if os.getenv('BOX4s_WAZUH') == "true":
        Dashboards.append(Dashboard(name='wazuh', url='/kibana/app/wazuh#?embed=true', parent_id='#siem', role='SIEM'))
except Exception:
    # BOX4s_WAZUH environment variable not defined. Ignored here.
    pass

RoleURLs = [
    # role : url
    {'name': 'Super Admin', 'url': '/user'},
    {'name': 'Filter', 'url': '/filter'},
    {'name': 'Updates', 'url': '/update'},
    {'name': 'User-Management', 'url': '/user'},
    {'name': 'FAQ', 'url': '/faq'},
    {'name': 'Dashboards-Master', 'url': '/start'},
    {'name': 'SIEM', 'url': '/siem-overview'},
    {'name': 'Schwachstellen', 'url': '/vuln-overview'},
    {'name': 'Netzwerk', 'url': '/network-overview'},
    {'name': 'Wiki', 'url': '/docs'},
    {'name': 'Alerts', 'url': '/alerts'},
    {'name': 'Config', 'url': '/config'},
]
