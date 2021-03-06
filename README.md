[1]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair

# Pinglist AWS Ansible

Ansible manifests to configure the Pinglist platform.

See also:
- [pinglist-aws-terraform](https://github.com/RichardKnop/pinglist-aws-terraform)
- [pinglist-api](https://github.com/RichardKnop/pinglist-api)
- [pinglist-app](https://github.com/RichardKnop/pinglist-app)
- [pinglist-ios-app](https://github.com/RichardKnop/pinglist-ios-app)

# Index

* [Pinglist AWS Ansible](#pinglist-aws-ansible)
* [Index](#index)
* [Requirements](#requirements)
  * [Requirements For AWS Provisioning](#requirements-for-aws-provisioning)
  * [Setting Up GPG-encrypted Vault Support](#setting-up-gpg-encrypted-vault-support)
  * [Encrypt / Decrypt Vault Password](#encrypt--decrypt-vault-password)
* [Provisioning](#provisioning)
* [Resources](#resources)

# Requirements

You need Ansible. Create a virtual Python environment and install requirements:

```
virtualenv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

To setup CoreOS hosts for Ansible, we will use coreos-bootstrap role:

```
ansible-galaxy install defunctzombie.coreos-bootstrap -p ./roles
```

## Requirements For AWS Provisioning

To successfully make an API call to AWS, you will need to configure `boto` (the Python interface to AWS). There are a variety of methods available, but the simplest is just to export two environment variables:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Test that the dynamic inventory file is working:

```
./ec2.py --list
```

Render an SSH configuration file, i.e.:

```
./render-ssh-config.sh <env-name-prefix>
```

## Setting Up GPG-encrypted Vault Support

You will need to have setup [gpg-agent](https://www.gnupg.org/) on your computer before you start.

```
brew install gpg
brew install gpg-agent
```

If you haven't already generated your PGP key (it's ok to accept the default options if you never done this before):

```
gpg --gen-key
```

Get your KEYID from your keyring:

```
gpg --list-secret-keys | grep sec
```

This will probably be pre-fixed with 2048R/ or 4096R/ and look something like 93B1CD02.

Send your public key to PGP key server:

```
gpg --keyserver pgp.mit.edu --send-keys KEYID
```

To import a public key (e.g. when a new engineer joins the team):

```
gpg --keyserver pgp.mit.edu --search-keys john@doe.com
```

Create `~/.bash_gpg`:

```
envfile="${HOME}/.gnupg/gpg-agent.env"

if test -f "$envfile" && kill -0 $(grep GPG_AGENT_INFO "$envfile" | cut -d: -f 2) 2>/dev/null; then
  eval "$(cat "$envfile")"
else
  eval "$(gpg-agent --daemon --log-file=~/.gpg/gpg.log --write-env-file "$envfile")"
fi
export GPG_AGENT_INFO  # the env file does not contain the export statement
```

Add to `~/.bash_profile`:

```
GPG_AGENT=$(which gpg-agent)
GPG_TTY=`tty`
export GPG_TTY

if [ -f ${GPG_AGENT} ]; then
  . ~/.bash_gpg
fi
```

Start a new shell or source the current environment:

```
source ~/.bash_profile
```

## Encrypt / Decrypt Vault Password

Encrypt the vault password:

```
echo "the vault password" | gpg -e -r "risoknop@gmail.com" > vault_password.gpg
```

Ansible will decrypt the file based using PGP key from your keyring. See `vault_password_file` option in the `ansible.cfg` configuration file.

## Required Secure Variables

This repository is using `ansible-vault` to secure sensitive information. Secure variables for each environment are stored in a separate file in `environments` directory:

```
.
├── environments
│   ├── stage.yml
│   └── prod.yml
│
└── ...
```

If you already know the password you do not need to recreate the `environments/<env-name-prefix>.yml` file.

You can edit variables stored in the vault:

```
ansible-vault edit environments/<env-name-prefix>.yml
```

Required contents for `environments/<env-name-prefix>.yml` (if you don't know the password):

```yml
database_max_open_conns: 5
database_max_idle_conns: 5
api_database_password: "database_password"
app_database_password: "app_database_password"
app_secret: "session_secret"
app_static_storage: "django.contrib.staticfiles.storage.StaticFilesStorage"
oauth_client_id: "oauth_client_id"
oauth_secret: "oauth_secret"
facebook_app_id: "facebook_app_id"
facebook_app_secret: "facebook_app_secret"
apns_platform_application_arn: "apns_platform_application_arn"
gcm_platform_application_arn: "gcm_platform_application_arn"
sendgrid_api_key: "sendgrid_api_key"
stripe_secret_key: "stripe_secret_key"
stripe_publishable_key: "stripe_publishable_key"
api_scheme: "https"
api_host: "<env-name-prefix>-app.{{ domain_name }}"
app_scheme: "https"
app_host: "<env-name-prefix>-api.{{ domain_name }}"
is_development: false
```

# Provisioning

In order to provision an environment, do something like:

```
make deploy DEPLOY_ENV=<env-name-prefix>
```

It's recommended to use verbose flags to see more output for debugging:

```
make deploy DEPLOY_ENV=<env-name-prefix> ARGS=-vvv
```

# Resources

- [How To Use GPG on the Command Line][1]
