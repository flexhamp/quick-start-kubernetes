#!/usr/bin/env bash
dnf install tc -y

dnf install network-scripts net-tools -y

ifconfig

cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-enp0s3
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp0s3
UUID=3e6aab7b-f07a-4a20-a782-0da2d1a36e32
DEVICE=enp0s3
ONBOOT=yes
IPADDR=192.168.100.112
PREFIX=24
GATEWAY=192.168.100.1
DNS1=8.8.8.8
DNS2=8.8.4.4
DNS3=192.168.100.1
IPV6_PRIVACY=no
EOF

systemctl restart network

# --------- Docker for Cnt8 --------------------------------------------------------
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

dnf install docker-ce-19.03.14-3.el8 docker-ce-cli-19.03.14-3.el8 containerd.io -y
mkdir /etc/docker

cat <<EOF >/etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "iptables": false
 }
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

#---------- Kubernetes for Cnt8 ----------------------------------------------------
iptables -P FORWARD ACCEPT
cat <<EOF >/etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay && \
modprobe br_netfilter

cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

dnf install kubelet-1.19* kubeadm-1.19* kubectl-1.19* --disableexcludes=kubernetes -y


systemctl enable kubelet

kubeadm init --pod-network-cidr=10.244.0.0/16

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml



