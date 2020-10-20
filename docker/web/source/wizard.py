from flask import redirect, Blueprint, render_template, url_for
from flask.helpers import flash
from wtforms_alchemy import ModelForm
from flask_wtf import FlaskForm
from source.extensions import db, ma


class WizardMiddleware():
    """BOX4security Wizard Middleware."""
    # Ordered list of steps
    steps = ['wizard.index', 'wizard.networks', 'wizard.box4s', 'wizard.systems', 'wizard.smtp', 'wizard.verify']

    def __init__(self, app):
        self.app = app
        self.url = '/wizard/'

    def __call__(self, environ, start_response):
        """Function is the main function called at each request to the middleware.
        The wizard middleware only applies if isShowWizard() returns true and
        the requested path is not an /api/ path or the wizard path itself.
        If it applies: redirect to self.url ('/wizard').
        If it does not apply, do nothing and pass the request to next middleware.
        """
        reqPath = environ.get('PATH_INFO')
        if self.isShowWizard() and not reqPath.startswith('/api/') and not reqPath.startswith(self.url):
            # If true, redirect to the wizard base URL (self.url) with status code 307
            status = "307 Temporary Redirect"
            headers = [('Location', self.url), ('Content-Length', '0')]
            start_response(status, headers)
            return [b'']
        # if the Wizard shall not be shown, cleanly exit the middleware without doing anything and continue the application flow.
        return self.app(environ, start_response)

    def isShowWizard(self):
        """Evaluate whether the Wizard shall be displayed."""
        return True

    @staticmethod
    def getMaxStep():
        """Return the maximum advanced step as endpoint string.

        For example:
        Returns 'wizard.systems' if the user has recently completed the box4s step but not yet the systems step.
        """
        # WIP CODE:
        # if System.query.count():
        if False:
            return 'wizard.box4s'
        else:
            return 'wizard.verify'

    @staticmethod
    def compareSteps(ep1, ep2):
        """Compare two step endpoints.
        Return 0 if ep1 and ep2 are the same step.
        Return -1 if ep1 is an earlier step than ep2.
        Return 1 if ep2 is an earlier step than ep1.
        """
        if ep1 == ep2:
            return 0
        elif WizardMiddleware.steps.index(ep1) < WizardMiddleware.steps.index(ep2):
            return -1
        else:
            return 1


wizard = Blueprint('wizard', __name__, template_folder='templates/wizard')


@wizard.route('/', methods=['GET', 'POST'])
def index():
    return render_template('index.html')


@wizard.route('/networks', methods=['GET', 'POST'])
def networks():
    return render_template('networks.html')


@wizard.route('/box4s', methods=['GET', 'POST'])
def box4s():
    endpoint = WizardMiddleware.getMaxStep()
    if endpoint == 'wizard.box4s':
        return render_template('box4s.html')
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen.', 'error')
        return redirect(url_for(endpoint))


@wizard.route('/systems', methods=['GET', 'POST'])
def systems():
    endpoint = WizardMiddleware.getMaxStep()
    if endpoint == 'wizard.systems':
        return render_template('systems.html')
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen.', 'error')
        return redirect(url_for(endpoint))


@wizard.route('/mail', methods=['GET', 'POST'])
def smtp():
    endpoint = WizardMiddleware.getMaxStep()
    if endpoint == 'wizard.smtp':
        return render_template('mail.html')
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen.', 'error')
        return redirect(url_for(endpoint))


@wizard.route('/verify', methods=['GET', 'POST'])
def verify():
    endpoint = WizardMiddleware.getMaxStep()
    if endpoint == 'wizard.verify':
        return render_template('verify.html')
    else:
        flash('Bevor Sie fortfahren können, müssen Sie zunächst die vorherigen Schritte abschließen.', 'error')
        return redirect(url_for(endpoint))


# class Network(db.Model):
#     """Network model class."""
#     # id = db.Column(db.Integer(), primary_key=True)
#     # name = db.Column(db.String(50), unique=True)


class System(db.Model):
    """System model class."""
    id = db.Column(db.Integer(), primary_key=True)
    name = db.Column(db.String(50), unique=True)


class AddNetworkForm(ModelForm, FlaskForm):
    pass
