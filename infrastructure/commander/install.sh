#!/bin/bash

set -eo pipefail
readonly LOG_FILE="$(pwd)/inst.log"
touch $LOG_FILE
exec 2>&1 >$LOG_FILE

echo "Commander private repo bash script start" 1>&2

# Sudo check
  if [ "$EUID" -ne 0 ] && [[ -z "${SUDO_USER// }" ]]
  then
    echo "Please run with sudo (root not allowed)" 1>&2
    exit
  fi

# SSH key generate.
  echo "Enter ssh passphrase for the new key : " 1>&2
  read -s gitpassword
  if [[ ${gitpassword} =~ " " ]]
  then
      echo "Must provide a valid password" 1>&2
      exit
  fi

  ssh-keygen -f /home/${SUDO_USER}/.ssh/commander -q -o -N ${gitpassword} -a 255 -t ed25519 -C "mempoule@commander"<<<y
  chmod 600 /home/${SUDO_USER}/.ssh/commander
  commander_pub=$(cat /home/${SUDO_USER}/.ssh/commander.pub)
  echo -e "" 1>&2
  echo -e "#######################################" 1>&2
  echo -e "COMMANDER KEY :" 1>&2
  echo -e "" 1>&2
  echo -e "${commander_pub}" 1>&2
  echo -e "" 1>&2
  echo -e "#######################################" 1>&2
  echo -e "" 1>&2

# Github.com add commander SSH key to config file.

  git_configfile_setup () {
    echo "Host github.com" >> /home/${SUDO_USER}/.ssh/config
    echo "Hostname github.com" >> /home/${SUDO_USER}/.ssh/config
    echo "IdentityFile ~/.ssh/commander" >> /home/${SUDO_USER}/.ssh/config
  }

  echo "GIT - Configuring git config file..." 1>&2

  if ! [ -f "/home/${SUDO_USER}/.ssh/config" ]
  then
    git_configfile_setup
  else
    echo "GIT - Config File exists, checking if commander is already in..." 1>&2
    occurences=$(grep -c 'IdentityFile ~/.ssh/commander' /home/${SUDO_USER}/.ssh/config) 1>&2
    if [ "${occurences}" == "0" ]
    then
      git_configfile_setup
    else
      echo "GIT - Commander entry already existing, skipped" 1>&2
    fi
  fi

# Github.com add to known_hosts
  echo "GIT - Add github.com to know host" 1>&2
  sudo -u ${SUDO_USER} ssh-keyscan github.com > /home/${SUDO_USER}/.ssh/known_hosts 2>/dev/null
  sudo -u ${SUDO_USER} ssh-keyscan 127.0.0.1 >> /home/${SUDO_USER}/.ssh/known_hosts 2>/dev/null

# Set chmode for .ssh
  chown -R ${SUDO_USER}:${SUDO_USER} /home/${SUDO_USER}/.ssh

# Check if the ssh-key was added, loops until done. Once done, Clone the repo
  while true;
  do
    keylist=$(curl -s https://github.com/mempoule.keys)
    commander_key_hash=$(echo "${commander_pub}" | cut -d ' ' -f2)

    if [[ "${keylist}" == *"${commander_key_hash}"*  ]]
    then
      break
    else
      echo -e "" 1>&2
      read -n 1 -s -r -p "GIT - Please add the Commander Key to mempoule user, then press a key to continue"
      echo -e "" 1>&2
    fi
  done

  sudo -u ${SUDO_USER} git clone git@github.com:mempoule/toolbox_private.git ~/toolbox_private
