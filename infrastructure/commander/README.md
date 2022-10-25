# Commander

## Installation

### Private repo

The full installation consists of 2 main steps :
 - Create and register SSH keys to be able to clone this private repo from github
 - Launch the installation playbook with ansible

### Public repo

    git clone https://github.com/mempoule/toolbox.git

    sudo apt-get install ansible -y

 - Go to [Step 2](#step-2---launch-the-installation-playbook)


### Prerequisites

 - 1 vCore
 - 2GB RAM
 - 30GB SSD
 - Linux OS, we will use Ubuntu Server (latest LTS version)

### Step 1 - SSH keys generation / registering and private repo clone

#### Create install.sh

`vi install.sh`

Paste the content of [install.sh](install.sh) and save the file

#### Make it executable

`chmod +x install.sh`

#### Run it with sudo

`sudo ./install.sh`

>   Note : During the process, you will get a new SSH Key, it is **mandatory** to add it to your github list of approved [SSH Keys](https://github.com/settings/keys). Otherwise you won't be able to clone this repo and finish the installation.

### Step 2 - Launch the installation playbook

#### Create the vault password file

    echo "Theultrasecurepassword" > ~/.vault_pass

#### Launch the playbook

    cd ~/toolbox/ansible

    ansible-playbook --connection=local -i 127.0.0.1, playbooks/commander.yml --ask-become-pass





