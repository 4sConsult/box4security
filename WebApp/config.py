POSTGRESQL_DB = 'box4S_db'
POSTGRESQL_USER = 'postgres'
POSTGRESQL_PASS = 'zgJnwauCAsHrR6JB'
POSTGRESQL_HOST = 'localhost'
POSTGRESQL_PORT = 5432
SQL_VERBOSE = False


class Config(object):
    SQLALCHEMY_DATABASE_URI = 'postgresql://{user}:{passw}@{host}:{port}/{db}'.format(
        user=POSTGRESQL_USER,
        passw=POSTGRESQL_PASS,
        host=POSTGRESQL_HOST,
        port=POSTGRESQL_PORT,
        db=POSTGRESQL_DB
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
