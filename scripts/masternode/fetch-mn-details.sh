#/!bin/bash
conf="/home/stashcore/.stashcore/stash.conf"
ipAddress=$(curl -s 4.icanhazip.com)
port=$( eval cat $conf | grep port | tail -1 | sed "s/port=//g" )
privateKey=$( eval cat $conf | grep masternodeprivkey | sed "s/masternodeprivkey=//g" )
echo "$HOSTNAME $ipAddress:$port $privateKey"