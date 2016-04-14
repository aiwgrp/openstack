#!/bin/bash -ex

source config.cfg

apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y

echo "########## Install and Config OpenvSwitch ##########"
apt-get install -y openvswitch-switch

apt-get install -y neutron-plugin-ml2 neutron-plugin-openvswitch-agent \
    neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent \
    neutron-plugin-openvswitch neutron-common

echo "########## Configuring br-int and br-ex for OpenvSwitch ##########"
sleep 5
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eno33554992

echo "########## Configuring IP for br-ex ##########"

ifaces=/etc/network/interfaces
test -f $ifaces.orig1 || cp $ifaces $ifaces.orig1
rm $ifaces
cat << EOF > $ifaces
# The loopback network interface
auto lo
iface lo inet loopback

auto eno16777736
iface eno16777736 inet static
address $LOCAL_IP
netmask $NETMASK_LOCAL

# The primary network interface
auto br-ex
iface br-ex inet static
address $MASTER
netmask $NETMASK_MASTER
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8

auto eno33554992
iface eno33554992 inet manual
 up ifconfig \$IFACE 0.0.0.0 up
 up ip link set \$IFACE promisc on
 down ip link set \$IFACE promisc off
 down ifconfig \$IFACE down
EOF

echo "########## Reboot machine after finishing configure IP ##########"
init 6
