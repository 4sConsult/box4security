from flask import Flask
from flask_user import UserManager
from source.config import Config
from source.models import User
from source.extensions import db, ma, mail

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)
ma.init_app(app)
mail.init_app(app)
userman = UserManager(app, db, User)

from . import routes  # noqa
# disable pep8 checks for this one
