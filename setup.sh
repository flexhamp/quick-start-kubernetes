#!/usr/bin/env bash
source "$(pwd)"/utils/root.sh
check_root
whoami

# Главное меню
function main_menu() {
  clear
  echo "Select an option:"
  printf "\n"
  echo "1 - Kubernetes"
  echo "2 - Docker"
  echo "3 - Preset Centos7"
  echo "0 - Exit"
  read -n 1 option
}

# Предустановка kubernetes
function preset_centos() {
  systemctl stop firewalld
  systemctl disable firewalld

  yum update -y
  yum install yum-utils -y && \
  yum install epel-release -y && \
  yum install htop mc tree vim -y

  mkdir ~/.ssh
  chmod 0700 ~/.ssh
  touch ~/.ssh/authorized_keys
  chmod 0644 ~/.ssh/authorized_keys
  ssh-keygen -t rsa -b 4096

  cat <<EOF >>~/.bashrc
PS1="\[\e[0;32m\][\u@\h \w]# \[\e[0m\] "
EOF
}

function action() {
  while [ 1 ]; do
    main_menu
    echo -ne "\n"
    case $option in
    1) sh "$(pwd)"/kubernetes/kubernetes.sh ;;
    2) sh "$(pwd)"/docker/docker.sh ;;
    3) preset_centos ;;
    0) break ;;
    esac
  done
  clear
}

action
