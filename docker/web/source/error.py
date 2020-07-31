"""Module to handle HTTP errors."""
from source import app
from flask import render_template
from flask_user import current_user
from source.config import RoleURLs


@app.errorhandler(403)
@app.route('/403', defaults={'e': 403})
@app.route('/403/<e>')
def forbidden(e):
    """Handle 403 Forbidden Error."""
    userRoleURLs = [d for d in RoleURLs if d['name'] in current_user.roles]
    for r in current_user.roles:
        for d in RoleURLs:
            if d['name'] == r.name:
                d_copy = d.copy()
                d_copy['description'] = r.description
                userRoleURLs.append(d_copy)
    return render_template('errors/403.html', roleURLs=userRoleURLs), 403
