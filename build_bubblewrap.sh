#!/bin/bash

base_path="$(realpath $(dirname $0))"
cd $base_path
. ./common.sh

print_help() {
  echo "Usage: ./build_bubblewrap.sh distro_name release_name arch"
}

assert_root
assert_deps "debootstrap"
assert_args "$3"

distro_name="$1"
release_name="$2"
arch="$3"

./build_package.sh $distro_name $release_name $arch \
  source_type=git \
  pkg_source=https://salsa.debian.org/debian/bubblewrap.git \
  pkg_branch="debian/0.11.0-2+deb13u1"