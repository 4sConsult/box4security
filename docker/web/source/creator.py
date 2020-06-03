"""Flask middleware to initialize app with an admin user."""
from werkzeug.wrappers import Request, Response
from flask_user import UserManager
from source.models import User, Role
from source.extensions import db
from flask import redirect, url_for


class CreatorUserMan(UserManager):
    """Extended UserManager class."""

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
                    sa.roles.append(Role.query.get(1))
                    db.session.add(sa)
                    db.session.commit()
            # Show login_view()
            return super().login_view()
        else:
            # First time, offer registration
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