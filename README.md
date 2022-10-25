```
.gitignore
ansible
   |-- ansible.cfg
   |-- playbooks
   |   |-- commander.yml
   |-- roles
   |   |-- apt
   |   |   |-- tasks
   |   |   |   |-- autoremove.yml
   |   |   |   |-- main.yml
   |   |   |   |-- update.yml
   |   |   |   |-- upgrade.yml
   |   |-- install
   |   |   |-- tasks
   |   |   |   |-- main.yml
   |   |   |-- vars
   |   |   |   |-- vars.json
bastion
   |-- README.md
   |-- bastion.py
   |-- setup.py
infrastructure
   |-- DKIM
   |   |-- README.md
   |-- commander
   |   |-- README.md
   |   |-- install.sh
   |-- pfSense
   |   |-- pfsense-vm.md
   |-- proxmox
   |   |-- README.md
   |   |-- install.sh
   |-- synology
   |   |-- backup.py
misc
   |-- README.md
```