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
_version="0.12.6.2"
_gitUser="stashpayio"
_name="stashcore-${_version}-x86_64-linux-gnu"
_path=~/deploy/bin
_bin="${_name}.tar.gz"
_daemon="stashd"
_binaries=${_path}/${_bin}
_binaryPath="https://github.com/${_gitUser}/stash/releases/download/v${_version}/${_bin}"

# Check OS Version is Ubuntu
release=$( lsb_release -cs ) || true

if [ "$release" != "trusty" ] &&
   [ "$release" != "xenial" ] &&
   [ "$release" != "trusty" ] &&
   [ "$release" != "bionic" ] &&
   [ "$release" != "cosmic" ] &&
   [ "$release" != "disco" ]; then  
   # Use generic release
   release=""
else
  # Use specific Ubuntu release
   release="-$release"   
fi

# Script Variables
_version="0.12.6.2"
_folder="stashcore-${_version}-x86_64-linux-gnu"
_binaries="${_folder}${release}.tar.gz"
_gitUser="stashpayio"
_binaryPath="https://github.com/${_gitUser}/stash/releases/download/v${_version}/${_binaries}"
_sentinelPath="https://github.com/stashpayio/sentinel.git"
_parametersPath="https://raw.githubusercontent.com/${_gitUser}/stash/master/zcutil/fetch-params.sh"

# download lastest binaries
echo "Checking for updates..."
mkdir -p ${_path} && pushd ${_path}
#rm ${_bin}
wget ${_binaryPath} -NP ${_path}
tar xzf ${_binaries}
pushd ${_name}/bin
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