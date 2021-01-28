#!/usr/bin/env bash
function main_menu() {
  clear
  echo "Select an option:"
  printf "\n"
  echo "1 - Install Docker(19.03)"
  echo "2 - Uninstall Docker"
  echo "0 - Exit"
  read -n 1 option
}

function install_docker() {
  yum install yum-utils -y
  yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

  # Для kubernetes 1.20 последняя стабильная версия docker 19.03
  yum install docker-ce-19.03.9-3.el7 docker-ce-cli-19.03.9-3.el7 containerd.io -y
  systemctl enable docker
  systemctl start docker

  if [ "$1" = 1 ]; then
    exit 0
  fi
}

function uninstall_docker() {
  echo "Caution. Deleting everything"
  read -n 1 -s -r -p "Press any key to continue"
  systemctl disable docker && \
  systemctl disable docker.socket

  docker stop "$(docker ps -q)" && \
  docker rm "$(docker ps -a -q)" && \
  docker rmi "$(docker images -q)" -f

  systemctl stop docker.socket && \
  systemctl stop docker

  yum remove docker* containerd.io -y
  rm -rf /var/lib/docker
}

while [ 1 ]; do
  if [ "$1" = 1 ]; then
    install_docker $1
  fi
  read -n 1 option
  main_menu
  echo -ne "\n"
  case $option in
  1) install_docker ;;
  2) uninstall_docker ;;
  0) break ;;
  esac
done
clear
