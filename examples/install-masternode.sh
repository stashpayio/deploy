#!/usr/bin/env bash

# Install Stash Core masternode on Ubuntu 18.04 LTS x64
set -e

# Ensure git and wget are available
sudo apt-get -y install wget git

# Fetch deploy utilities
git clone https://github.com/stashpayio/deploy.git

# Run install node script
cd deploy/scripts && ./install-node.sh masternode