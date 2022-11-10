#!/bin/bash


########################################################################
#     vars
########################################################################

TIMESTAMP=$(date "+%Y%m%d%H%M%S")
LOGFILE="/var/log/mempoule-totp-$TIMESTAMP.log"
TIMESTAMP=$(date "+%Y%m%d%H%M%S")

users_activated=0
users_already_set=0
users_activated_nomail=0
domains_exist=0
totp_activated=0

total_users=$(grep -c '^user:' /etc/pve/user.cfg)
mail_users=$(grep '^user:.*.:.*.:.*.:.*.:.*.@.*.\..*.:' /etc/pve/user.cfg)
admin_list=$(pveum acl list | grep '\/ .*.Administrator\|PVEAdmin\|PVESysAdmin' | cut -d '@' -f1 | rev | cut -d ' ' -f1 | rev)
admin_with_mail=0


########################################################################
#     forcemode
########################################################################

if [[ "$1" == "force" ]]
then
  echo "$TIMESTAMP - FORCEMODE : ON" | tee $LOGFILE
else
  echo "$TIMESTAMP - FORCEMODE : OFF" | tee $LOGFILE
fi


########################################################################
#    One mail minimum to avoid locking out
########################################################################

if [[ "${mail_users}" =~ root ]]
then
  admin_with_mail=$((admin_with_mail+1))
else
  while IFS= read -r line; do
    if [[ "${mail_users}" =~ "${line}" ]]
    then
      admin_with_mail=$((admin_with_mail+1))
    fi
  done < <(printf '%s\n' "${admin_list}")
fi

if ! [[ "${admin_with_mail}" -gt 0 ]]
then
  exit
else
  echo "$TIMESTAMP - At least one admin has got a mail" | tee $LOGFILE
fi

echo "lalala"
########################################################################
#    TOTP status check
########################################################################

if [ -f /etc/pve/domains.cfg ]
then
  echo "$TIMESTAMP - Domains.cfg already exists" | tee $LOGFILE
  domains_exist=1
  if [ "$(grep -c 'tfa type=oath' /etc/pve/domains.cfg)" -eq 1 ]
  then
    echo "$TIMESTAMP - TOTP already activated" | tee $LOGFILE
    totp_activated=1
  fi
else
  echo "$TIMESTAMP - Domains.cfg not found" | tee $LOGFILE
  domains_exist=0
fi

########################################################################
#    /etc/pve/user.cfg parsing
########################################################################

send_totp() {
  echo "$1 $2 $3 $4 $5"
}

while IFS= read -r line; do
  if [[ ${line} =~ ^user: ]]
  then
    username=$(echo "${line}" | cut -d ":" -f2 | cut -d "@" -f1)
    first_name=$(echo "${line}" | cut -d ":" -f6)
    last_name=$(echo "${line}" | cut -d ":" -f5)
    mail_address=$(echo "${line}" | cut -d ":" -f7)
    cur_totp=$(echo "${line}" | cut -d ":" -f9)
    if [ -z "${cur_totp}" ]
    then
      cur_totp=$(oathkeygen)
      echo "NEW TOTP ${cur_totp}"
      new_line=$(sed "s/:/:${cur_totp}/8" <<< $line)
      sed -i "/${line}/c${new_line}" /etc/pve/user.cfg
      if [ -z "${mail_address}" ]
      then
        users_activated_nomail=$((users_activated_nomail+1))
      else
        send_totp ${username} ${first_name} ${last_name} ${mail_address} ${cur_totp}
      fi
      users_activated=$((users_activated+1))
    else
      users_already_set=$(( users_already_set+1 ))
      echo "${username} already have a TOTP key" | tee $LOGFILE
      if [[ "$1" == "force" ]]
      then
        if ! [ -z "${mail_address}" ]
        then
          send_totp ${username} ${first_name} ${last_name} ${mail_address} ${cur_totp}
        fi
      fi
    fi
  fi
done < "/etc/pve/user.cfg"



echo "Total Users activated : ${users_activated}"
echo "Total Users activated without mail : ${users_activated_nomail}"
echo "Total Users already set : ${users_already_set}"
