#!/usr/bin/env bash
# Install Stashcore mining pool on Ubuntu 18.04 LTS x64

# Usage 
# ./install-pool.sh port1 port2 payoutAddress
set -e

conf="/home/stashcore/.stashcore/stash.conf"
installScript="install-node.sh"
ipAddress=$(curl -s 4.icanhazip.com)
poolConf="/root/node_modules/stratum-pool/pool.js"

if [ "$(whoami)" != "root" ]; then
  echo "Script should be run as user: root"
  exit 1
fi

if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "$0 port1 port2 payoutAddress"
    exit 1
fi

# Check OS Version is Ubuntu 18.04 or 18.10
. /etc/lsb-release

if [ "$DISTRIB_RELEASE" != "18.04" ] && 
   [ "$DISTRIB_RELEASE" != "18.10" ]; then
  echo "WARNING: This script has been designed to work with Ubuntu 18.04+"
  exit 1 # Comment out to ignore warning
fi

if [ ! -f $conf ]; then
    echo "Could not find $conf"

    if [ -f $installScript ]; then
      echo "A new Stash Core node will be set up..."
      ./$installScript
    else
      echo "Please install Stash Core node before continuing."
      exit 1
    fi    
fi

_rpcUserName=$( eval cat $conf | grep rpcuser | sed "s/rpcuser=//g" )
_rpcPassword=$( eval cat $conf | grep rpcpassword | sed "s/rpcpassword=//g" )
_rpcPort=$( eval cat $conf | grep rpcport | sed "s/rpcport=//g" )
_poolPort1=$1
_poolPort2=$2
_mining_address=$3

sudo apt-get -y update
sudo apt-get -y install build-essential python

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
. ~/.nvm/nvm.sh
nvm install v10.12.0
npm install -g forever
mkdir -p ~/node_modules
git clone https://github.com/stashpayio/node-stratum-pool.git ~/node_modules/stratum-pool
pushd ~/node_modules/stratum-pool
npm install
popd

cat <<EOF > ${poolConf}

var myCoin = {
    "name": "Stash",
    "symbol": "STASH",
    "algorithm": "x11",
    "nValue": 1024, //optional - defaults to 1024
    "rValue": 1, //optional - defaults to 1
    "txMessages": false, //optional - defaults to false,
    /* Magic value only required for setting up p2p block notifications. It is found in the daemon
       source code as the pchMessageStart variable.
       For example, litecoin mainnet magic: http://git.io/Bi8YFw
       And for litecoin testnet magic: http://git.io/NXBYJA */
     "peerMagic": "aa1b69b0", //optional
     "peerMagicTestnet": "efa2faf7" //optional
};

var Stratum = require('stratum-pool');

var pool = Stratum.createPool({
    "coin": myCoin,
    "address": "$_mining_address", //Address to where block rewards are given    
    "rewardRecipients": {
        "22851477d63a085dbc2398c8430af1c09e7343f6": 0.01
    },
    "blockRefreshInterval": 1000, //How often to poll RPC daemons for new blocks, in milliseconds
    "jobRebroadcastTimeout": 55,    
    "connectionTimeout": 600, //Remove workers that haven't been in contact for this many seconds    
    "emitInvalidBlockHashes": false,
    "tcpProxyProtocol": false,
    "banning": {
        "enabled": false,
        "time": 600, //How many seconds to ban worker for
        "invalidPercent": 50, //What percent of invalid shares triggers ban
        "checkThreshold": 500, //Check invalid percent when this many shares have been submitted
        "purgeInterval": 300 //Every this many seconds clear out the list of old bans
    },
    "ports": {
        "$_poolPort1": { //A port for your miners to connect to
            "diff": 0.00002, //the pool difficulty for this port      
            "varDiff": {
                "minDiff": 0.00002, //Minimum difficulty
                "maxDiff": 512, //Network difficulty will be used if it is lower than this
                "targetTime": 15, //Try to get 1 share per this many seconds
                "retargetTime": 90, //Check to see if we should retarget every this many seconds
                "variancePercent": 30 //Allow time to very this % from target without retargeting
            }
        },
        "$_poolPort2": { //Another port for your miners to connect to, this port does not use varDiff
        "diff": 0.00002 //The pool difficulty
        }
    },    
    "daemons": [
        {   //Main daemon instance
            "host": "127.0.0.1",
            "port": $_rpcPort,
            "user": "$_rpcUserName",
            "password": "$_rpcPassword"
        }//,
        // {   //Backup daemon instance
        //     "host": "127.0.0.1",
        //     "port": 19344,
        //     "user": "litecoinrpc",
        //     "password": "testnet"
        // }
    ],
    "p2p": {
        "enabled": false,        
        "host": "127.0.0.1",
        "port": 9999,
        "disableTransactions": true
    }

}, function(ip, port , workerName, password, callback){ //stratum authorization function
    console.log("Authorize " + workerName + ":" + password + "@" + ip);
    callback({
        error: null,
        authorized: true,
        disconnect: false
    });
});

pool.on('share', function(isValidShare, isValidBlock, data){
  if (isValidBlock)
      console.log('Block found');
  else if (isValidShare)
      console.log('Valid share submitted');
  else if (data.blockHash)
      console.log('We thought a block was found but it was rejected by the daemon');
  else
      console.log('Invalid share submitted')

  console.log('share data: ' + JSON.stringify(data));
});

/*
'severity': can be 'debug', 'warning', 'error'
'logKey':   can be 'system' or 'client' indicating if the error
          was caused by our system or a stratum client
*/
pool.on('log', function(severity, logKey, logText){
  console.log(severity + ': ' + '[' + logKey + '] ');
});

pool.start();
EOF

# work around for 'first time crontab error'
if ! crontab -l 2>/dev/null | grep "#some random string"; then
  (crontab -l; echo "") | crontab - 
fi

if ! crontab -l | grep "PATH=/root/.nvm/versions/node/v10.12.0/bin:$PATH"; then
  (crontab -l; echo "PATH=/root/.nvm/versions/node/v10.12.0/bin:$PATH") | crontab -
fi

if ! crontab -l | grep "@reboot sleep 20 && /root/.nvm/versions/node/v10.12.0/bin/forever start ${poolConf}"; then
  (crontab -l; echo "@reboot sleep 20 && /root/.nvm/versions/node/v10.12.0/bin/forever start ${poolConf}") | crontab -
fi

ufw allow ${_poolPort1}/tcp
ufw allow ${_poolPort2}/tcp

/root/.nvm/versions/node/v10.12.0/bin/forever start ${poolConf}

cat <<EOF

********************************************************************************
*                         Stash Pool install complete                          *
********************************************************************************

Stash pool setup complete. Please note the following:

EOF
echo -n "URL of mining pool: "; tput bold; tput setaf 2; echo "stratum+tcp://${ipAddress}:${_poolPort1}"; tput sgr0
echo -n "Payout addres: "; tput bold; tput setaf 2; echo "${_mining_address}"; tput sgr0
echo -n "Username: "; tput bold; tput setaf 2; echo "anything"; tput sgr0
echo -n "Password: "; tput bold; tput setaf 2; echo "anything"; tput sgr0

cat <<EOF

To connect for example using ccminer
ccminer.exe -a x11 -o stratum+tcp://${ipAddress}:${_poolPort1}

To see forever process type:
> source ~/.bashrc

Then type 
> forever list

To change pool config settings update this file then reboot:
> nano $poolConf

EOF