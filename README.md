# Server Inventory

## Preparation
### Clone Repository
```
git clone https://github.com/Khanif363/server-inventory.git
cd server-inventory
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
gd.nama-gedung_r.rack-number_u.unit-number_ty.server-type ansible_host=ip_address ansible_user=username ansible_port=ssh_port
```

## How Operate?
### Method 1 (With Credential)
#### Local Server (Non-Docker)
##### Create Encrypted Variables (for each host/server/vm)
```
ansible-vault create inventory/host_vars/gd.nama-gedung_r.rack-number_u.unit-number_ty.server-type.yml
```
[gd.nama-gedung_r.rack-number_u.unit-number_ty.server-type].yml gd.nama-gedung_r.rack-number_u.unit-number_ty.server-type is inventory_hostname of your server in inventory/hosts.ini
then and add this variables
```
ansible_password: your_server_password
ansible_become_pass: your_server_password
```

##### Run Script
```
ansible-playbook playbooks/collect_system_report.yml --ask-vault-pass
```

#### Local Server (With-Docker)
##### Install Docker Engine
Doc: https://docs.docker.com/engine/install/
##### Build & Deploy Container
```
docker compose build
docker compose up -d
```
##### Create Encrypted Variables (for each host/server/vm)
```
docker compose exec ansible-control-old ansible-vault create inventory/host_vars/gd.nama-gedung_r.rack-number_u.unit-number_ty.server-type.yml
```
[gd.nama-gedung_r.rack-number_u.unit-number_ty.server-type].yml gd.nama-gedung_r.rack-number_u.unit-number_ty.server-type is inventory_hostname of your server in inventory/hosts.ini
then and add this variables
```
ansible_password: your_server_password
ansible_become_pass: your_server_password
```

##### Run Script
```
docker compose exec ansible-control-old ansible-playbook playbooks/collect_system_report.yml --ask-vault-pass
```


### Method 2 (With SSH Key)
#### Target Server
##### Permit Access sudo without password
```
echo "username ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/username
chmod 440 /etc/sudoers.d/username
```

#### Local Server
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