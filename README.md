# Server Inventory

## Preparation
### Clone Repository
```
git clone https://github.com/Khanif363/server-inventory.git
```
### Install Ansible (Local)
```
apt install pipx
pipx install --include-deps ansible
```

### Configuration
Parameters need to adjust:
- username
- ip_server
- port
- inventory/hosts.ini (example from hosts.example.ini)
#### sample
```
#hosts.ini
hostname_server_vm ansible_host=ip_address ansible_user=username ansible_port=ssh_port
```

## How Operate?
### Method 1 (With Credential)
#### Server Local
##### Create Encrypted Variables (for each host/server/vm)
```
ansible-vault create inventory/host_vars/server1.yml
```
[server1].yml server1 is hostname of your server in inventory/hosts.ini
then and add this variables
```
ansible_password: your_server_password
ansible_become_pass: your_server_password
```

##### Run Script
```
ansible-playbook playbooks/collect_system_report.yml --ask-vault-pass
```


### Method 2 (With SSH Key)
#### Server Target
##### Permit Access sudo without password
```
echo "username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/username
chmod 440 /etc/sudoers.d/username
```

#### Server Local
##### Allow Remote Connection
```
ssh-copy-id -p 22 username@ip_server
```
##### Install ansible community package (jika diperlukan)
```
ansible-galaxy collection install community.general
```
##### Run Script
```
ansible-playbook playbooks/collect_system_report.yml
```

##### Rollback Configuration
```
sudo rm /etc/sudoers.d/username
```