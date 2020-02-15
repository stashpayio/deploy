#!/usr/bin/env bash
# Install Stashcore node on Ubuntu 18.04 LTS x64

# Usage
# ./install.sh [masternode] [testnet] [debug]

# Examples

#./install.sh
#./install.sh testnet
#./install.sh masternode
#./install.sh masternode testnet
set -e
_version="0.12.7.0"
_rc='-rc1'
_gitUser="stashpayio"

_name="stashcore-${_version}${_rc}-x86_64-linux-gnu"
_folder="stashcore-${_version}-x86_64-linux-gnu"
_path=~/deploy/bin
_bin="${_name}.tar.gz"
_daemon="stashd"
_binaries=${_path}/${_bin}
_binaryPath="https://github.com/${_gitUser}/stash/releases/download/v${_version}${_rc}/${_bin}"


cat <<EOF

********************************************************************************
*                            Stash Core Installer v0.1                         *
********************************************************************************

This script will upgrade to Stash Core ${_version}${_rc}

EOF

printf  "Continue with upgrade? (y/n) "

read -t 60 REPLY
if [ ${REPLY} != "y" ]; then
  exit 1
fi

# download lastest binaries
echo "Checking for updates..."
mkdir -p ${_path} && pushd ${_path}
#rm ${_bin}
wget ${_binaryPath} -NP ${_path}
tar xzf ${_binaries}
pushd ${_folder}/bin
shaExisting=$( sha256sum /usr/bin/${_daemon} | awk '{print $1;}' )
shaUpgrade=$( sha256sum ${_daemon} | awk '{print $1;}' )

echo "Existing version: $shaExisting"
echo "Upgrade version: $shaUpgrade"

if [ "$shaUpgrade" != "$shaExisting" ]; then 
  echo "New version found. Stopping daemon...please wait for 30 seconds"
  systemctl stop ${_daemon}.service && sleep 30
  cp stash* /usr/bin
  echo "Restarting daemon..."
  systemctl restart ${_daemon}.service
  echo "Upgrade complete."
else
  echo "No new version found."
fi
