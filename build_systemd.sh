#!/bin/bash

base_path="$(realpath $(dirname $0))"
cd $base_path
. ./common.sh

print_help() {
  echo "Usage: ./build_systemd.sh distro_name release_name arch"
}

assert_root
assert_deps "debootstrap"
assert_args "$3"

distro_name="$1"
release_name="$2"
arch="$3"

./build_package.sh $distro_name $release_name $arch \
  source_type=apt \
  pkg_source=systemd \
  patches=systemd_$release_name.patch