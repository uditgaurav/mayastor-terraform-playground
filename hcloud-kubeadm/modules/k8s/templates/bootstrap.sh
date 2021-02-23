#!/bin/bash
set -eu

export DEBIAN_FRONTEND=noninteractive

waitforapt(){
  while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
     echo "Waiting for other software managers to finish..."
     sleep 1
  done
}

apt-get -qy install \
%{for install_package in install_packages~}
	${install_package} \
%{endfor~}

# Static network config
# Fix hetzner not giving us IP via DHCP after 1st lease (24h)
# FIXME: supports only ipv4, ipv6 is disabled
ipv4=$(ip -j a l dev eth0 | jq -r '.[] | select(.ifname=="eth0").addr_info | .[] | select(.family=="inet" and .scope=="global").local')
prefixlen=$(ip -j a l dev eth0 | jq '.[] | select(.ifname=="eth0").addr_info | .[] | select(.family=="inet" and .scope=="global").prefixlen')
matching_configurations=$(ip -j a l dev eth0 | jq '.[] | select(.ifname=="eth0").addr_info | .[] | select(.family=="inet" and .scope=="global")' | jq --slurp 'length')
nameservers=$(grep ^nameserver /etc/resolv.conf | cut -f2 -d' ' | xargs echo)
matching_default_routes=$(ip -4 -j route list default dev eth0 | jq length)
gateway=$(ip -4 -j route list default | jq -r '.[].gateway')
if [ "$matching_configurations" -ne 1 ] || [ -z "$ipv4" ] || [ "$prefixlen" -ne 32 ] || [ -z "$nameservers" ] || [ "$matching_default_routes" -ne 1 ] || [ -z "$gateway" ]; then
	echo "*** Cannot safely determine global IPv4 address, please investigate command to get current ip in 'bootstrap.sh'"
	exit 1
fi
waitforapt
apt-get -qqy install ifupdown
apt-get -qqy --purge remove netplan.io
apt-get -qqy --purge autoremove
rm -fr /etc/netplan
echo 'source /etc/network/interfaces.d/*' > /etc/network/interfaces
echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
if ! grep -q 'net.ifnames=0 biosdevname=0' /etc/default/grub; then
	sed -i -es'/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 net.ifnames=0 biosdevname=0"/' /etc/default/grub
	grep 'net.ifnames=0 biosdevname=0' /etc/default/grub
	update-grub
fi
cat > /etc/network/interfaces.d/lo.cfg << EOF
auto lo
iface lo inet loopback
EOF
cat > /etc/network/interfaces.d/eth0.cfg << EOF
auto eth0
iface eth0 inet static
    address $ipv4
    netmask 255.255.255.255
    gateway $gateway
    pointopoint $gateway
    dns-nameservers $nameservers
EOF

apt-get -qq install -y kubelet kubeadm

mv -v "${server_upload_dir}/10-kubeadm.conf" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

systemctl daemon-reload
systemctl restart kubelet
