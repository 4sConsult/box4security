from wtforms_alchemy import ModelForm
from flask_wtf import FlaskForm
from wtforms import TextField, BooleanField, SelectMultipleField
from source.models import User


class AddUserForm(ModelForm, FlaskForm):
    """Add User Form."""

    class Meta:
        """Build form from User Model.

        Exclude internal stuff and password.
        Don't set validators so the three name fields are not required.
        """

        model = User
        exclude = ['active', 'email_confirmed_at', 'password']
    first_name = TextField(validators=[])
    last_name = TextField(validators=[])
    email_copy = BooleanField()
    roles = SelectMultipleField(
        'Rollen',
        coerce=int
    )
