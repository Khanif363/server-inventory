# server-inventory

## Preparation
### Install Ansible
`apt install pipx`
`pipx install --include-deps ansible`
### Configuration
Parameters need to adjust:
- username
- ip_server
- port
- inventory/hosts.ini (example from hosts.example.ini)

## Server Target(RUN COMMAND)
### Permit Access sudo without password
`echo "username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/username`
`chmod 440 /etc/sudoers.d/username`

## Server Local
### Allow Remote Connection
`ssh-copy-id -p 22 username@ip_server`
### Install ansible community package (jika diperlukan)
`ansible-galaxy collection install community.general`
### Run Script
`ansible-playbook playbooks/collect_system_report.yml`

### Rollback Configuration
`sudo rm /etc/sudoers.d/username`