import os
import pwd


def drop_privileges():
    if os.geteuid() != 0:
        # already non root
        return
    username = os.getenv('SUDO_USER')
    pwnam = pwd.getpwnam(username)

    os.seteuid(pwnam.pw_uid)


def raise_privileges():
    if os.geteuid() == 0:
        # already root
        return

    os.seteuid(0)
