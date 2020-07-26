#!/bin/bash
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: July, 2018
# Author: gerald.venzl@oracle.com
# Description: Installs Oracle database software
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Abort on any error
set -e


[[ $DEBUG -gt 0 ]] && echo DEBUG set to $DEBUG
[[ $DEBUG -gt 1 ]] && set -x

. /vagrant/scripts/functions.sh

declare -A proxy

echo 'INSTALLER: Started up'
echo 'Installation method:' $OR_INSTALLATION_METHOD

[[ $DEBUG -gt 0 ]] && echo ENV && env

for f in /vagrant/userscripts/pre.d/*; do
  case "${f,,}" in
    *.sh)
      echo "INSTALLER: Running $f"
      . "$f"
      echo "INSTALLER: Done running $f"
      ;;
    *)
      echo "INSTALLER: Ignoring $f"
      ;;
  esac
done

# Get Proxy information
if [ -n "$HTTPS_PROXY" ]; then
  extract_proxy $HTTPS_PROXY
elif [ -n "$HTTP_PROXY" ]; then
  extract_proxy $HTTP_PROXY
fi

# Download orcharhino installer
curl -s -o /root/install_orcharhino.sh https://acc-pub.atix.de/orcharhino_installer/${OR_INSTALLER_VERSION}/install_orcharhino.sh 
chmod +x /root/install_orcharhino.sh

# get Installer version
eval installer_version=$(grep SCRIPT_VERSION= /root/install_orcharhino.sh | awk -F '=' '{print $2}')
echo Using orcharhino installer version $installer_version

echo "respect proxy settings"
set_proxy_cmd_options

# Workaround for rhn on oracle
if is_oracle; then
  yum -y install rhn-client-tools
fi

# register to ACC
echo Register to ACC
/root/install_orcharhino.sh $cmd_proxy_options -a -y -n $HOSTNAME --register-only $OR_INSTALLER_EXTRA_PARAMS $OR_ACTIVATION_KEY 

# get latest orcharhino version
or_version=$(get_latest_or_version)

# fix locale warning
# yum reinstall -y glibc-common
echo LANG=en_US.utf-8 >> /etc/environment
echo LC_ALL=en_US.utf-8 >> /etc/environment

echo 'INSTALLER: Locale set'

# set system time zone
sudo timedatectl set-timezone $SYSTEM_TIMEZONE
echo "INSTALLER: System time zone set to $SYSTEM_TIMEZONE"

case $OR_INSTALLATION_METHOD in
  "webgui")
    cmd_options=""
    ;;
  "default" | "full")
    echo create the answers.yaml
    create_answers_yaml $OR_INSTALLATION_METHOD
    cmd_options="-- -- --skip-gui"
    ;;
  *)
    echo ERROR: no installation methid defined!
    exit 1
    ;;
esac

print_answers_yaml

[ $DEBUG -gt 0] && echo /root/install_orcharhino.sh $cmd_proxy_options -a -y $OR_ACTIVATION_KEY $cmd_options

/root/install_orcharhino.sh $cmd_proxy_options -a -y $OR_INSTALLER_EXTRA_PARAMS $OR_ACTIVATION_KEY $cmd_options

if [ $? -eq 1 ]; then
    echo "INSTALLER: Installation complete, orcharhino ready to use!";
fi
