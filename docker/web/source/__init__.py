from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from flask_mail import Mail
from flask_user import UserManager
from source.config import Config
from source.models import User

app = Flask(__name__)
app.config.from_object(Config)
db = SQLAlchemy(app)
ma = Marshmallow(app)
mail = Mail(app)
userman = UserManager(app, db, User)


from . import routes  # noqa
# disable pep8 checks for this one
