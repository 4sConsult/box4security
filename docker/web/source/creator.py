"""Flask middleware to initialize app with an admin user."""
from werkzeug.wrappers import Request, Response
from flask_user import UserManager, EmailError
from source.models import User, Role
from source.extensions import db
from flask import redirect, url_for, flash, request
from urllib.parse import quote
from flask_mail import Mail
from datetime import datetime


class CreatorUserMan(UserManager):
    """Extended UserManager class."""

    def trySMTP(self):
        """Test the SMTP Connection.

        Returns True if sending mails works, else False.
        """
        try:
            self.email_adapter.send_email_message("box@4sconsult.de", "SMTP-TEST", "", "", "box@4sconsult.de", "BOX4security")
        except EmailError:
            return False
        return True

    def unauthenticated_view(self):
        """Prepare a Flash message and redirect to USER_UNAUTHORIZED_ENDPOINT."""
        # Prepare Flash message
        flash("You do not have permission to access the BOX4security.", 'error')
        url = request.url
        # Redirect to USER_UNAUTHENTICATED_ENDPOINT
        safe_next_url = self.make_safe_url(url)
        return redirect(self._endpoint_url(self.USER_UNAUTHENTICATED_ENDPOINT) + '?next=' + quote(safe_next_url))

    def unauthorized_view(self):
        """Rdirect to USER_UNAUTHORIZED_ENDPOINT."""
        # Redirect to USER_UNAUTHORIZED_ENDPOINT
        return redirect(self._endpoint_url(self.USER_UNAUTHORIZED_ENDPOINT))

    def login_view(self):
        """Extend default login view.

        Redirect to register_view() if no user exists.
        Add user to Super Admin role if only one exists (this is the case after first login).
        """
        if self.db_manager.db_adapter.find_objects(User):
            # Users exist => dont show register view
            if User.query.count() == 1:
                # Only one user => add to Super Admin if not already is
                sa = User.query.first()
                if Role.query.get(1) not in sa.roles:
                    # Likely the first time this method is called => also check for SMTP
                    smtpState = self.trySMTP()
                    if not smtpState:
                        # SMTP not working => need to mark the user as confirmed
                        sa.email_confirmed_at = datetime.now()
                    sa.roles.append(Role.query.get(1))
                    db.session.add(sa)
                    db.session.commit()
            # Show login_view()
            return super().login_view()
        else:
            # First time, offer registration
            # try SMTP
            smtpState = self.trySMTP()
            if not smtpState:
                # SMTP not working => don't require to send "Welcome E-Mail"
                # Still need to confirm the user.
                self.USER_SEND_REGISTERED_EMAIL = False
            return super().register_view()

    def register_view(self):
        """Extend default register view.

        Redirect login_view() to register_view() if at least 1 user exists.
        Does not allow registering after the first user has registered.
        Other users must be added over the WebApp.
        Add Super Admin rule to the first user.
        """
        if self.db_manager.db_adapter.find_objects(User):
            return super().login_view()
        else:
            # First time, offer registration
            return super().register_view()
