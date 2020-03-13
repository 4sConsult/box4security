from . import config
import sqlalchemy as sa

engine = sa.create_engine('postgresql://{user}:{passw}@{host}:{port}/{db}'
                          .format(user=config.POSTGRESQL_USER,
                                  passw=config.POSTGRESQL_PASS,
                                  host=config.POSTGRESQL_HOST,
                                  port=config.POSTGRESQL_PORT,
                                  db=config.POSTGRESQL_DB), echo=config.SQL_VERBOSE)
Session = sa.orm.sessionmaker(bind=engine)
session = Session()
