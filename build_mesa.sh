#!/bin/bash

base_path="$(realpath $(dirname $0))"
cd $base_path
. ./common.sh

print_help() {
  echo "Usage: ./build_mesa.sh distro_name release_name arch branch"
}

assert_root
assert_deps "debootstrap"
assert_args "$4"

distro_name="$1"
release_name="$2"
arch="$3"
branch="$4"

./build_package.sh $distro_name $release_name $arch \
  source_type=git \
  pkg_source=https://salsa.debian.org/xorg-team/lib/mesa-amber.git \
  pkg_branch="$branch"