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
    userRoleURLs = []
    # loop over all roles
    for r in current_user.roles:
        for d in RoleURLs:
            if d['name'] == r.name:
                # and create a copy of the Role URL configuration
                d_copy = d.copy()
                # add the text description of role to the Role URL element
                d_copy['description'] = r.description
                userRoleURLs.append(d_copy)
    # render the 403 navigation page with the user roles, their description and URL
    return render_template('errors/403.html', roleURLs=userRoleURLs), 403
