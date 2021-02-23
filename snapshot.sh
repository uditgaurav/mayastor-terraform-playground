#! /bin/bash

set -e

rm /etc/localtime; ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

# set timezone to UTC
rm /etc/localtime; ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime
echo 'Etc/UTC' > /etc/timezone
# Is this really needed?
cat << EOF | debconf-set-selections
tzdata  tzdata/Zones/Indian     select
tzdata  tzdata/Zones/Asia       select
tzdata  tzdata/Zones/Australia  select
tzdata  tzdata/Zones/SystemV    select
tzdata  tzdata/Areas            select  Etc
tzdata  tzdata/Zones/Africa     select
tzdata  tzdata/Zones/US         select
tzdata  tzdata/Zones/Pacific    select
tzdata  tzdata/Zones/Etc        select  UTC
tzdata  tzdata/Zones/Europe     select
tzdata  tzdata/Zones/Arctic     select
tzdata  tzdata/Zones/Antarctica select
tzdata  tzdata/Zones/Atlantic   select
tzdata  tzdata/Zones/America    select
keyboard-configuration  keyboard-configuration/unsupported_layout       boolean true
keyboard-configuration  keyboard-configuration/unsupported_config_layout        boolean true
keyboard-configuration  keyboard-configuration/optionscode      string
keyboard-configuration  keyboard-configuration/variant  select  English (US)
keyboard-configuration  keyboard-configuration/switch   select  No temporary switch
keyboard-configuration  keyboard-configuration/layout   select  English (US)
keyboard-configuration  keyboard-configuration/modelcode        string  pc105
keyboard-configuration  keyboard-configuration/unsupported_config_options       boolean true
keyboard-configuration  keyboard-configuration/variantcode      string
keyboard-configuration  keyboard-configuration/layoutcode       string  us
keyboard-configuration  keyboard-configuration/altgr    select  The default for the keyboard layout
keyboard-configuration  keyboard-configuration/unsupported_options      boolean true
keyboard-configuration  keyboard-configuration/store_defaults_in_debconf_db     boolean true
keyboard-configuration  keyboard-configuration/toggle   select  No toggling
keyboard-configuration  keyboard-configuration/xkb-keymap       select  gb
keyboard-configuration  keyboard-configuration/model    select  Generic 105-key PC (intl.)
keyboard-configuration  keyboard-configuration/compose  select  No compose key
keyboard-configuration  keyboard-configuration/ctrl_alt_bksp    boolean false
EOF
dpkg-reconfigure -f noninteractive tzdata
dpkg-reconfigure -f noninteractive keyboard-configuration

# set fireall to use iptables-legacy (required for k8s to work - or was in the
# past)
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# disable ipv6 altogether for now
echo 'net.ipv6.conf.all.disable_ipv6 = 1' > /etc/sysctl.d/01-disable-ipv6.conf
sysctl 'net.ipv6.conf.all.disable_ipv6=1'

# basic firewall, proper one is set using modules.k8s.null_resource.cluster_firewall
# NOTE: on master.sh firewall is replaced by one with port 6443 open
mkdir -p /etc/iptables
cat > /etc/iptables/rules.v4 << EOF
*mangle
:PREROUTING ACCEPT
-F PREROUTING
-A PREROUTING -i eth0 -m tcp -p tcp --dport 22 -j ACCEPT
-A PREROUTING -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A PREROUTING -i eth0 -j DROP
COMMIT
EOF

cat > /etc/systemd/system/local-iptables.service << EOF
[Unit]
Description=Local firewall
DefaultDependencies=no
Wants=network-pre.target systemd-modules-load.service local-fs.target
Before=network-pre.target shutdown.target
After=systemd-modules-load.service local-fs.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/iptables-restore --noflush --table mangle /etc/iptables/rules.v4
ExecStop=/bin/true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable local-iptables.service
systemctl start local-iptables.service

# disable systemd-resolvd as it breaks coredns & kubelet resolving
# https://coredns.io/plugins/loop/#troubleshooting
# https://askubuntu.com/questions/907246/how-to-disable-systemd-resolved-in-ubuntu

rm /etc/resolv.conf
grep ^nameserver /run/systemd/resolve/resolv.conf > /etc/resolv.conf
systemctl stop systemd-resolved
systemctl disable systemd-resolved

apt-get -qq update
apt-get -qq install -y vim jq
echo 'set mouse=' > /root/.vimrc
echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
systemctl restart sshd

# install docker
echo "
Package: docker-ce
Pin: version ${docker_version}.*
Pin-Priority: 1000
" > /etc/apt/preferences.d/docker-ce
apt-get -qq update
apt-get -qq install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get -qq update && apt-get -qq install -y docker-ce

cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver":"overlay2"
}
EOF

systemctl restart docker.service

# install kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "
Package: kubelet
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubelet

echo "
Package: kubeadm
Pin: version ${kubernetes_version}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubeadm

apt-get install linux-modules-extra-5.8.0-29-generic

# TODO: remove old kernel

apt-get clean
apt-get -qq update
apt-get -qqd install -y kubelet kubeadm
