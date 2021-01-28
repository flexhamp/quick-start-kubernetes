#!/usr/bin/env bash
#trap ctrl_c INT

function main_menu() {
  clear
  echo "Select an option:"
  printf "\n"
  echo "1 - Install Kubernetes"
  echo "2 - Install Dashboard"
  echo "3 - Uninstall Kubernetes"
  echo "4 - Uninstall Dashboard"
  echo "0 - Exit"
  read -n 1 option
}

# Предустановка kubernetes
function preset_kubernetes() {
  printf "\n"
  echo "Selinux and swap will be disabled"
  #  read -n 1 -s -r -p "Press any key to continue"
  # Отключение selinux
  setenforce 0
  sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
  # Отключение swap
  sed -i '/swap/d' /etc/fstab
  swapoff -a
}

function install_packages_kubernetes() {
  echo "The packages kubelet-1.20.2-0, kubeadm-1.20.2-0, kubectl-1.20.2-0 will be installed"
  #  read -n 1 -s -r -p "Press any key to continue"
  cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
  # Выбираем версию 1.20.2-0, для которой производим настройки
  yum install kubelet-1.20.2-0 kubeadm-1.20.2-0 kubectl-1.20.2-0 -y
  systemctl enable kubelet
  systemctl start kubelet
  return 0
}

function kubeadm_init() {
  cat <<EOF >/etc/docker/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
  systemctl restart docker

  kubeadm init --pod-network-cidr=10.244.0.0/16
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

  #  В дефолтной конфигурации мастер-нода не запускает контейнеры,
  #  так как занимается отслеживанием состояния кластера и перераспределением ресурсов.
  #  Ввод данной команды даст возможность запускать контейнеры на мастере, собенно, если кластер содержит лишь одну ноду:
  kubectl taint nodes --all node-role.kubernetes.io/master-
}

function install_dashboard() {
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
  mkdir -p ~/dashboard
  cp "$(pwd)"/kubernetes/dashboard/dashboard-admin.yaml ~/dashboard
  cp "$(pwd)"/kubernetes/dashboard/dashboard-read-only.yaml ~/dashboard
  cp "$(pwd)"/kubernetes/dashboard/dashboard.sh ~/dashboard
  chmod +x ~/dashboard/dashboard.sh
  ln -s ~/dashboard/dashboard.sh /usr/local/bin/dashboard
  dashboard start
}

function delete_dashboard() {
  dashboard stop
}

function setup_kubernetes() {
  preset_kubernetes
  sh "$(pwd)"/docker/docker.sh 1
  install_packages_kubernetes
  kubeadm_init
  #  read -n 1 -s -r -p "Press any key to continue"
}

function delete_kubernetes() {
  kubeadm reset -f
  systemctl restart docker
  systemctl stop kubelet
  systemctl disable kubelet
  yum remove kubeadm kubectl kubelet kubernetes-cni kube* -y
  find / -name "*kube*"
  rm -rf /etc/kubernetes
  rm -rf ~/.kube

  #  docker stop "$(docker ps -q)"
  #  docker rm "$(docker ps -a -q)"
  #  docker rmi "$(docker images -q)" -f
  #  systemctl disable docker
  #  systemctl disable docker.socket
  #  systemctl stop docker
  #  systemctl stop docker.socket
  #  yum install docker-ce-19.03.9-3.el7 docker-ce-cli-19.03.9-3.el7 containerd.io -y
  #  rm -rf /var/lib/docker
  read -n 1 -s -r -p "Press any key to continue"
}

#function ctrl_c() {
#  echo -ne "\nTrapped CTRL-C"
#}

while [ 1 ]; do
  main_menu
  echo -ne "\n"
  case $option in
  1) setup_kubernetes ;;
  2) install_dashboard ;;
  3) delete_kubernetes ;;
  4) delete_dashboard ;;
  0) break ;;
  esac
done
clear
