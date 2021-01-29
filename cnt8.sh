#!/usr/bin/env bash
dnf install tc -y

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

modprobe overlay
modprobe br_netfilter

cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
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

dnf install kubelet-1.20.2-0 kubeadm-1.20.2-0 kubectl-1.20.2-0 -y
systemctl enable kubelet

kubeadm init --pod-network-cidr=10.244.0.0/16
