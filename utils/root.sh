#!/usr/bin/env bash

function check_root () {
  if [[ $EUID -ne 0 ]]; then
    echo "Этот сценарий должен выполняться от имени root"
    exit 1
  fi
}