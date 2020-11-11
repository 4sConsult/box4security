from source.models import User
from .models import BOX4security, System, Network, WizardState
from source.extensions import db


class WizardMiddleware():
    """BOX4security Wizard Middleware."""
    # Ordered list of steps
    steps = ['wizard.index', 'wizard.networks', 'wizard.systems', 'wizard.box4s', 'wizard.smtp', 'wizard.verify']

    @staticmethod
    def isShowWizard():
        """Evaluate whether the Wizard shall be displayed.

        See wizard/models.py
        See also docker/web/migrations/versions/031dd699edaa_add_wizard_state.py
        """
        state = WizardState.query.first()
        if state:
            return state.state.id == 2
        else:
            # No saved state: Likely new installation. Display Wizard.
            return True

    @staticmethod
    def forceDisableWizard():
        """Forcefully disable the Wizard.

        See wizard/models.py
        See also docker/web/migrations/versions/031dd699edaa_add_wizard_state.py
        """
        state = WizardState.query.first()
        state.state_id = 1
        db.session.add(state)
        db.session.commit()

    @staticmethod
    def setCompleted():
        """Set the wizard to be completed.

        See wizard/models.py
        See also docker/web/migrations/versions/031dd699edaa_add_wizard_state.py"""
        state = WizardState.query.first()
        state.state_id = 3
        db.session.add(state)
        db.session.commit()

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
