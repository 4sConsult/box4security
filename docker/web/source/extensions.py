"""The module holding and initializing all Flask extensions."""
from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from flask_mail import Mail
from flask_migrate import Migrate

db = SQLAlchemy()
ma = Marshmallow()
mail = Mail()
migrate = Migrate()
