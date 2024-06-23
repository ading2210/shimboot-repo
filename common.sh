#!/bin/bash

set -e
if [ "$DEBUG" ]; then
  set -x
  export DEBUG=1
fi

check_deps() {
  local needed_commands="$1"
  for command in $needed_commands; do
    if ! command -v $command &> /dev/null; then
      echo " - $command"
    fi
  done
}

assert_deps() {
  local needed_commands="$1"
  local missing_commands=$(check_deps "$needed_commands")
  if [ "${missing_commands}" ]; then
    echo "You are missing dependencies needed for this script."
    echo "Commands needed:"
    echo "${missing_commands}"
    exit 1
  fi
}

parse_args() {
  declare -g -A args
  for argument in "$@"; do
    if [ "$argument" = "-h" ] || [ "$argument" = "--help" ]; then
      print_help
      exit 0
    fi

    local key=$(echo $argument | cut -f1 -d=)
    local key_length=${#key}
    local value="${argument:$key_length+1}"
    args["$key"]="$value"
  done
}

assert_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "this needs to be run as root."
    exit 1
  fi
}

assert_args() {
  if [ -z "$1" ]; then
    print_help
    exit 1
  fi
}

get_distro_info() {
  local distro_name="$1"
  local arch="$2"

  if [ "$distro_name" = "debian" ]; then
    local repo_url="http://deb.debian.org/debian"
    local components="main"

  elif [ "$distro_name" = "ubuntu" ]; then
    if [ "$arch" = "amd64" ]; then
      local repo_url="http://archive.ubuntu.com/ubuntu"
    else 
      local repo_url="http://ports.ubuntu.com"
    fi
    local components="main universe"

  else
    echo "invalid distro name"
    exit 1
  fi

  echo "$repo_url|$components"
}