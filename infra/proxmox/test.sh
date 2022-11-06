#!/bin/bash

########################################################################
# Script config & logging
########################################################################
set -eo pipefail
readonly LOG_FILE="$(pwd)/start.log"
touch $LOG_FILE
exec 2>&1 >$LOG_FILE

echo "LALALA" 1>&2

scriptpath="$(pwd)/${0##*/}"

apt-get install sudo

if [ "$(ls /home | wc -l)" -eq 0 ]
then
   printf "\033c" 1>&2
   echo "No user on this system, create ? (y/n)" 1>&2
   read decision
   if [ "${decision}" == "y" ]
   then
      echo "Enter user name : " 1>&2
      read username
      echo "Enter password : " 1>&2
      read -s password
      if ! [[ "${username}" =~ [^[:alnum:]]+ ]] && ! [[ ${password} =~ " " ]]
      then
         pass=$(perl -e 'print crypt($ARGV[0], "password")' ${password})
         useradd -m -p ${pass} ${username} --shell /bin/bash
         usermod -aG sudo ${username}
         # prereq for nic reporting
         usermod -aG www-data ${username}
      else
         echo "Must provide a valid user / password" 1>&2
         exit
      fi
   else
      echo "Need one user to get the install running, aborting" 1>&2
      exit
   fi
else
   echo "An user is already added, skipping" 1>&2
   exit
fi