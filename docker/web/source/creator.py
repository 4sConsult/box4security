"""Flask middleware to initialize app with an admin user."""
from werkzeug.wrappers import Request, Response
from flask_user import UserManager
from source.models import User


class CreatorUserMan(UserManager):
    """Extended UserManager class."""

    def login_view(self):
        """Extend default login view.

        Redirect to register_view() if no user exists.
        """
        if self.db_manager.db_adapter.find_objects(User):
            return super().login_view()
        else:
            # First time, offer registration
            return super().register_view()

    def register_view(self):
        """Extend default register view.

        Redirect login_view() to register_view() if at least 1 user exists.
        Does not allow registering after the first user has registered.
        Other users must be added over the WebApp.
        """
        if self.db_manager.db_adapter.find_objects(User):
            return super().login_view()
        else:
            # First time, offer registration
            return super().register_view()
