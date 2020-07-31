from . import app
import os


@app.template_filter()
def custom_getenv(default, var):
    """Get an environment variable in jinja2 template.
    Return content of `default` if the variable does not exist.
    """
    try:
        return os.getenv(var, default)
    except Exception:
        return default
