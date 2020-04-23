"""Module to handle HTTP errors."""
from source import app
from flask import render_template


@app.errorhandler(403)
@app.route('/403')
def forbidden():
    """Handle 403 Forbidden Error."""
    return render_template('errors/403.html'), 403
