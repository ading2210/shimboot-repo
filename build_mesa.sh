#!/bin/bash

set -e
if [ "$DEBUG" ]; then
  set -x
fi

print_help() {
  echo "Usage: ./build_mesa.sh [arch]"
}

if [ "$EUID" -ne 0 ]; then 
  print_help
  echo "This script must be run as root."
  exit 1
fi

if [ "$1" ]; then
  arch="$1"
else
  arch="amd64"
fi

release_name="bookworm"
base_path="$(realpath $(dirname $0))"
tmp_dir="/tmp/chromeos-systemd"
qemu_dir="$base_path/qemu"
disk_img="$qemu_dir/$release_name-$arch.img"

echo "creating build directory"
build_dir="$base_path/build"
rm -rf $build_dir || true
mkdir -p $build_dir
cd $build_dir

echo "downloading package source"
source_dir="$build_dir/mesa-amber"
git clone --depth=1 "https://salsa.debian.org/xorg-team/lib/mesa-amber.git" "$source_dir"

echo "setting up sbuild virtual machine"
mkdir -p $qemu_dir
if [ ! -f "$disk_img" ]; then
  sbuild-qemu-create --arch=$arch $release_name https://deb.debian.org/debian -o $disk_img
fi

echo "building package"
cd $source_dir
build_log="$base_path/build_$release_name_$arch.log"
sbuild-qemu --image=$disk_img --ram=4096 --cpus=$(nproc --all) --arch=$arch --no-run-piuparts --no-run-lintian