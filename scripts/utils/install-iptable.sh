#/!bin/bash
set -ex

_dnsPortFrom=$1
_dnsPortTo=$2
_protocol="tcp"
#_protocol="udp"

sudo iptables -A PREROUTING -t nat -p $_protocol --dport $_dnsPortFrom -j REDIRECT --to-port $_dnsPortTo
apt-get install -y iptables-persistent