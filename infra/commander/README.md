# Commander

### Prerequisites

 - 1 vCore
 - 2GB RAM
 - 30GB SSD
 - Linux OS, we will use Ubuntu Server (latest LTS version)

## Installation

### Clone repo

    git clone https://github.com/mempoule/toolbox.git

### Install Ansible

    sudo apt-get update
    sudo apt-get install ansible -y

### Clone private version (optional)

    cd ~/toolbox/infra/commander
    chmod +x install.sh
    sudo ./install.sh

>   Note : During the process, you will get a new SSH Key, it is **mandatory** to add it to your github list of approved [SSH Keys](https://github.com/settings/keys). Otherwise you won't be able to clone this repo and finish the installation.

### Create the vault password file

    echo "Theultrasecurepassword" > ~/.vault_pass

#### Launch the playbook

    cd ~/toolbox/ansible
    ansible-playbook -i hosts/mempoule.yml playbooks/commander.yml -K





