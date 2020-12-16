![](docs/box4security.png)

Open-source powered SIEM, Vulnerability Scanning, Host- & Network-IDS. All wrapped in a modern Python web app and shipped in Docker containers.   
The BOX4security builds upon solid blocks like Elastic Stack, OpenVAS, and Suricata to deliver security insights. Additionally, it features one-click updating, automatized installation, easy configuration through an initial wizard, and a role-based permission model for web and API access. 

We welcome you to try it out and take hold of your network's security.


# Install
We provide an automated method of installation via a bash script.

**Currently only Ubuntu 20.04 LTS Server is supported and tested.** 

Remark: While the installation script is designed to have the same outcome every time it is run (idempotency), it is recommended to launch the installation from a stable console. We recommend running it in a `screen` session.

Before you start the installation, be sure that at the current state, the installation script includes the following system modifications:

* New packages will be installed to resolve dependencies.
* A new folder `/data` will be created in your root directory. The folder serves for data storage of Elasticsearch and Suricata alerts and flows.
* A new sudo user called `amadmin` will be created on the system.
* The BOX4security service will be enabled.
* The systems' nameserver will be set to the proxying DNS server included in the BOX4security. It can be configured using the initial wizard.
* The BOX4security will be installed to `/opt/box4s/` and its configs will be copied from the cloned repo folder `/etc/box4s`.

After cloning you should edit and replace the default credentials in:
* `config/secrets/*.conf`
* `docker/elastalert/etc/elastalert/smtp_auth_file.yaml`

Once you are ready, the installation is as simple as: 
```
git clone https://github.com/4sConsult/box4security.git
# Edit configuration files before running install.sh!
sudo /bin/bash /box4security/scripts/Automation/install.sh
```

The script may ask you some questions and will notify you about the progress.

After it is done, browse to `https://YOUR_SERVER_IP`

# Contribute
## Our Philosophy

BOX4security started as an in-house product, developed here at 4sConsult.
It is used in security assessments of customers' networks while also allowing a permanent installation in the environment.  

By going open-source we no longer withheld the software stack from the public and instead want to engage with the security community. Anyone is free to contribute and create a fork of this repository. As with all products, we ask you to respect the license. While anyone is free to use the product in commercial use, we kindly ask you to contribute backward by creating pull requests upstream. This way, all users of the BOX4security can evaluate and 

We are also happy to help you get started with the repository and contributing to it!
Don't hesitate to reach out to our engineers by dropping an [email](mailto:box@4sconsult.de) in our mailbox.

Fairly often smaller and *easy-fix* issues are deliberately left open for newer contributors. Browse for *help-wanted* and *good-first-issue* to 

## Bug Reporting and Feature Requests
### Security
**DO NOT** publish security vulnerabilities or possible exploits on any platforms, including this repository's issues tab. Instead, drop us an [email](mailto:box@4sconsult.de), so we can take a look at it.
Possibly, remotely accessible instances of this software may be affected by your findings!

### General Bugs and Feature Requests
Any other forms of findings and requests are very welcome to be posted and discussed publicly on the issues tab of this repository.

# License
As introduced in the contribution section, the BOX4security is licensed under the [AGPL-3.0](LICENSE) ([TL;DR](https://tldrlegal.com/license/gnu-affero-general-public-license-v3-(agpl-3.0))).