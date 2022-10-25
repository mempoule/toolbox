#!/bin/bash

########################################################################
# Script config & logging
########################################################################
set -eo pipefail
readonly LOG_FILE="$(pwd)/start.log"
touch $LOG_FILE
exec 2>&1 >$LOG_FILE

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

ssh_client=$(who am i|cut -d"(" -f2 |cut -d")" -f1)
echo "IP used for iptables/fail2ban : ${ssh_client}" 1>&2

########################################################################
# IPV6 stop
########################################################################
echo "Disabling IPV6..." 1>&2
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

########################################################################
# Update & Install
########################################################################

echo "Update and Install packages..." 1>&2
# rm /etc/apt/sources.list
# rm /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://ftp.debian.org/debian buster main contrib" >> /etc/apt/sources.list
echo "deb http://ftp.debian.org/debian buster-updates main contrib" >> /etc/apt/sources.list
echo "# PVE pve-no-subscription repository provided by proxmox.com," >> /etc/apt/sources.list
echo "# NOT recommended for production use" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" >> /etc/apt/sources.list
echo "# security updates" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security buster/updates main contrib" >> /etc/apt/sources.list
apt update && apt -y full-upgrade
apt-get install curl unzip wget fail2ban htop -y

########################################################################
# Config base proxmox
########################################################################

echo "Base server config..." 1>&2
awk '{ printf "# "; print; }' /etc/fail2ban/fail2ban.conf | tee /etc/fail2ban/jail.local
echo "[DEFAULT]" >> /etc/fail2ban/jail.local
echo "ignoreip = ${ssh_client}" >> /etc/fail2ban/jail.local

sed -i '/^PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/^#PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/^#PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
sed -i '/^PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config

echo "export EDITOR=vim" >> /root/.bashrc
echo -e "alias ll='ls -alF'" >> /root/.bashrc
echo -e "alias iptables='/sbin/iptables'" >> /root/.bashrc
echo -e "alias ifconfig='/sbin/ifconfig'" >> /root/.bashrc
echo "set nocompatible" >> /root/.vimrc
echo "set mouse-=a" >> /root/.vimrc

echo "export EDITOR=vim" >> /home/${username}/.bashrc
echo -e "alias ll='ls -alF'" >> /home/${username}/.bashrc
echo -e "alias iptables='/sbin/iptables'" >> /home/${username}/.bashrc
echo -e "alias ifconfig='/sbin/ifconfig'" >> /home/${username}/.bashrc
echo "set nocompatible" >> /home/${username}/.vimrc
echo "set mouse-=a" >> /home/${username}/.vimrc

/sbin/pveum user add ${username}@pam
/sbin/pveum acl modify / --roles Administrator --users ${username}@pam

########################################################################
# Basic iptables rules
########################################################################

echo "IPtables rules..." 1>&2
service fail2ban stop
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 8006 -j ACCEPT
iptables -A INPUT -j DROP

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get -y install iptables-persistent

########################################################################
# SSH key add
########################################################################

echo "Adding SSH keys..." 1>&2
mkdir /home/${username}/.ssh 2>/dev/null
chmod 700 /home/${username}/.ssh 2>/dev/null
keylist=$(curl -s https://github.com/mempoule.keys)
while IFS= read -r key
do
  echo "$key" >> /home/mempoule/.ssh/authorized_keys
done <<< "$keylist"

chmod 600 /home/${username}/.ssh/authorized_keys
chown -R ${username}:${username} /home/${username}/.ssh

########################################################################
# Daemon Restart
########################################################################

systemctl disable systemd-networkd-wait-online.service
systemctl mask systemd-networkd-wait-online.service

systemctl restart fail2ban
systemctl restart ssh


########################################################################
# Basic ISO get
########################################################################

wget https://releases.ubuntu.com/18.04.5/ubuntu-18.04.5-live-server-amd64.iso -P /var/lib/vz/template/iso/
wget https://frafiles.netgate.com/mirror/downloads/pfSense-CE-2.6.0-RELEASE-amd64.iso.gz -P /var/lib/vz/template/iso/
cd /var/lib/vz/template/iso/
gunzip pfSense-CE-2.6.0-RELEASE-amd64.iso.gz
wget https://releases.ubuntu.com/focal/ubuntu-20.04.5-live-server-amd64.iso -P /var/lib/vz/template/iso/
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.1-live-server-amd64.iso -P /var/lib/vz/template/iso/
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -P /var/lib/vz/template/iso/

echo "Install Complete !" 1>&2


########################################################################
# Breaking OVH defaukt raid0
########################################################################

echo "OVH installation Softraid Bypassed ? (y/n)" 1>&2
read optional_rewrap
if [ "${optional_rewrap}" == "y" ]
then
  echo "Optional softraid tweak activated" 1>&2
  loc_mapper_name=$(df -h | grep mapper | cut -d ' ' -f1)
  loc_vg_name=$(/sbin/pvs --separator "," | grep dev | xargs | cut -d "," -f2)
  lsblk | grep -v '^loop' 1>&2
  echo "Please specify the disk to add to existing vg" 1>&2
  read loc_unused_disk
  if ! [[ "${loc_unused_disk}" =~ [^[:alnum:]]+ ]]
      then
        echo "/sbin/wipefs /dev/${loc_unused_disk}" 1>&2
        echo "/sbin/pvcreate /dev/${loc_unused_disk} -f" 1>&2
        echo "/sbin/vgextend ${loc_vg_name} /dev/${loc_unused_disk}" 1>&2
        echo "/sbin/lvresize --extents +100%FREE --resizefs ${loc_mapper_name}" 1>&2
      else
         echo "Must provide a valid disk" 1>&2
         exit
      fi
fi

