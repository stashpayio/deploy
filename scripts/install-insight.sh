# Usage ./install-insight.sh [testnet]
set -e

_network=$( echo "$HOSTNAME" | cut -d- -f1 )
_daemon_user="stashcore"
_configPath=/home/$_daemon_user/.stashcore
_configFile=${_configPath}/stash.conf
_configFileInsight=$HOME/.stashcore/stashcore-node.json
_nodeVersionExplorer="v6.17.1"
_git="https://github.com/stashpayio"

# Network variables
_port="9999"
_rpcPort="9998"
_testPort="19999"
_testRpcPort="19998"
_insightPort="2095"
_testnet="0"

for i in "$@"; do

  if [ "$i" == "testnet" ]; then 
    _testnet="1"
    _port=$_testPort
    _rpcPort=$_testRpcPort    
  fi

done

_rpcUserName=$( cat $_configFile | grep rpcuser | sed "s/rpcuser=//g" )
_rpcPassword=$( cat $_configFile | grep rpcpassword | sed "s/rpcpassword=//g" )

cat <<EOF
Stash insight explorer will be installed configured as follows:
Testnet:    ${_testnet}"
Port:       ${_port}
RPC port:   ${_rpcPort}
EOF

printf  "Continue with install? (y/n) "

read -t 60 REPLY
if [ ${REPLY} != "y" ]; then
  exit 1
fi

# Allow additional ports
ufw allow ${_insightPort} # insight
ufw allow ${_insightPort}/tcp # insight

echo "uacomment=bitcore" >> ${_configFile}

# Install insight config
cat <<EOF > ${_configFileInsight}
{
  "network": "$_network",
  "port": $_insightPort,
  "https": false,
  "httpsOptions": {
    "key": "/root/.ssl/key.pem",
    "cert": "/root/.ssl/server.self.cert"
  },
  "services": [
    "stashd",
    "@stashcore/insight-api",
    "@stashcore/insight-ui",
    "web"
  ],
  "servicesConfig": {
    "@stashcore/insight-ui": {
      "routePrefix": "",
      "apiPrefix": "api"
    },
    "@stashcore/insight-api": {
      "routePrefix": "api"
    },
    "stashd": {
      "connect": [
        {
          "rpchost": "127.0.0.1",
          "rpcport": $_rpcPort,
          "rpcuser": "$_rpcUserName",
          "rpcpassword": "$_rpcPassword",
          "zmqpubrawtx": "tcp://127.0.0.1:28332"
        }
      ]
    }
  }
}
EOF

# Install insight

sudo apt-get -y install libzmq3-dev python build-essential

mkdir -p ~/explorer && pushd ~/explorer

git clone ${_git}/insight-api.git && \
git clone ${_git}/insight-ui.git && \
git clone ${_git}/stashcore-node.git && \
git clone ${_git}/stashcore-lib.git && \
git clone ${_git}/stashcore-p2p.git && \
git clone ${_git}/stashd-rpc.git

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
popd
. ~/.nvm/nvm.sh
nvm install ${_nodeVersionExplorer}
pushd ~/explorer/stashcore-node && \
npm install && \
npm link ../stashcore-lib/ && \
npm link ../stashcore-p2p/ && \
npm link ../insight-ui/ && \
npm link ../stashd-rpc/ && \
pushd ../insight-api/ && \
npm link ../stashcore-lib/ && \
popd && \
npm link ../insight-api && \
popd
npm install forever -g

# Create a cronjob for making sure stashd runs after reboot
if ! crontab -l 2>/dev/null | grep "#node maintenance scripts"; then
  (crontab -l; echo "") | crontab - # work around for 'first time crontab error'
fi

if ! crontab -l | grep "PATH=/root/.nvm/versions/node/${_nodeVersionExplorer}/bin:$PATH"; then
  (crontab -l; echo "PATH=/root/.nvm/versions/node/${_nodeVersionExplorer}/bin:$PATH") | crontab -
fi

if ! crontab -l | grep "@reboot /root/.nvm/versions/node/${_nodeVersionExplorer}/bin/forever start ~/explorer/stashcore-node/bin/stashcore-node start"; then
  (crontab -l; echo "@reboot /root/.nvm/versions/node/${_nodeVersionExplorer}/bin/forever start ~/explorer/stashcore-node/bin/stashcore-node start") | crontab -
fi

cat <<EOF
Insight installation complete. Please reindex and reboot.
EOF