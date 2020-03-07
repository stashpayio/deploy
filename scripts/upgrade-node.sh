#!/usr/bin/env bash
# Install Stashcore node on Ubuntu 18.04 LTS x64

# Usage
# ./install.sh [masternode] [testnet] [debug]

# Examples

#./install.sh
#./install.sh testnet
#./install.sh masternode
#./install.sh masternode testnet
set -ex
_version="0.12.7.0"
_rc=''
_gitUser="stashpayio"

_name="stashcore-${_version}${_rc}-x86_64-linux-gnu"
_folder="stashcore-${_version}-x86_64-linux-gnu"
_path=~/deploy/bin
_bin="${_name}.tar.gz"
_daemon="stashd"
_binaries=${_path}/${_bin}
_binaryPath="https://github.com/${_gitUser}/stash/releases/download/v${_version}${_rc}/${_bin}"

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
  echo "New version found. Stopping daemon..."
  systemctl stop ${_daemon}.service && sleep 10
  cp stash* /usr/bin
  echo "Restarting daemon..."
  systemctl restart ${_daemon}.service
else
  echo "No new version found."
fi

echo "Done."