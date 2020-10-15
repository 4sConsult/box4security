from flask import Flask
from source.config import Config
from source.extensions import db, ma, mail, migrate
from source.models import User
from source.creator import CreatorUserMan
from source.wizard import Wizard

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)
ma.init_app(app)
mail.init_app(app)
migrate.init_app(app, db)
userman = CreatorUserMan(app, db, User)
app.wsgi_app = Wizard(app.wsgi_app)

from . import helpers # noqa
from . import routes  # noqa
# disable pep8 checks for this one
