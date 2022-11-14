# Commander

### Prerequisites

 - 1 vCore
 - 2GB RAM
 - 30GB SSD
 - Linux OS, we will use Ubuntu Server (latest LTS version)

## Installation

### Clone & config repo

    git clone git@github.com:mempoule/toolbox.git
    cd ~/toolbox
    git config user.name "mempoule"
    git config user.email "115656864+mempoule@users.noreply.github.com"

### Generate Commander SSH key set and clone toolbox_private

    cd ~/toolbox/infra/commander
    sudo ./ssh_key_gen.sh

### Install Ansible

    sudo apt-get update
    sudo apt-get install ansible -y

#### Launch the playbook

    cd ~/toolbox/ansible
    ansible-playbook -i hosts/mempoule.yml playbooks/commander.yml -K







