from source.models import User
from .models import BOX4security, System, Network


class WizardMiddleware():
    """BOX4security Wizard Middleware."""
    # Ordered list of steps
    steps = ['wizard.index', 'wizard.networks', 'wizard.systems', 'wizard.box4s', 'wizard.smtp', 'wizard.verify']

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

    @staticmethod
    def isShowWizard():
        """Evaluate whether the Wizard shall be displayed.

        Currently, the wizard is shown, if no user exists and not BOX4s info was entered."""
        return not User.query.count() and not BOX4security.query.count()

    @staticmethod
    def getMaxStep():
        """Return the maximum advanced step as endpoint string.

        For example:
        Returns 'wizard.systems' if the user has recently completed the box4s step but not yet the systems step.
        """
        if BOX4security.query.order_by(BOX4security.id.asc()).count():
            # BOX4security exists, next step is smtp or verify
            return 'wizard.verify'
        if System.query.count():
            # Systems apart from BOX4s exist, next step is box4s
            return 'wizard.box4s'
        elif Network.query.count():
            # Network is defined, next step BOX4s
            return 'wizard.systems'
        else:
            # Nothing yet defined, max step is networks
            return 'wizard.networks'

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
