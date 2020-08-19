from . import app
import os
import string
import secrets


@app.template_filter()
def custom_getenv(default, var):
    """Get an environment variable in jinja2 template.
    Return content of `default` if the variable does not exist.
    """
    try:
        return os.getenv(var, default)
    except Exception:
        return default


def generate_password():
    """Generate a ten-character alphanumeric password.

    with at least one lowercase character,
    at least one uppercase character,
    and at least three digits
    See: https://docs.python.org/3/library/secrets.html#recipes-and-best-practices
    """
    alphabet = string.ascii_letters + string.digits
    while True:
        password = ''.join(secrets.choice(alphabet) for i in range(10))
        if (any(c.islower() for c in password) and any(c.isupper() for c in password) and sum(c.isdigit() for c in password) >= 3):
            break
    return password
