from flask import redirect, Blueprint, render_template
from wtforms_alchemy import ModelForm
from flask_wtf import FlaskForm


class WizardMiddleware():
    """BOX4security Wizard Middleware."""
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


wizard = Blueprint('wizard', __name__, template_folder='templates/wizard')


@wizard.route('/', methods=['GET', 'POST'])
def index():
    return render_template('index.html')


@wizard.route('/networks', methods=['GET', 'POST'])
def networks():
    return render_template('networks.html')


@wizard.route('/box4s', methods=['GET', 'POST'])
def box4s():
    return render_template('box4s.html')


@wizard.route('/systems', methods=['GET', 'POST'])
def systems():
    return render_template('systems.html')


@wizard.route('/mail', methods=['GET', 'POST'])
def smtp():
    return render_template('mail.html')


@wizard.route('/verify', methods=['GET', 'POST'])
def verify():
    return render_template('verify.html')


class AddNetworkForm(ModelForm, FlaskForm):
    pass
