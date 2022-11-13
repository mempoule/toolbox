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


### Generate Commander SSH key set and clone toolbox_private

    cd ~/toolbox/infra/commander
    ./ssh_key_gen.sh


#### Launch the playbook

    cd ~/toolbox/ansible
    ansible-playbook -i hosts/mempoule.yml playbooks/commander.yml -K





