#!/bin/bash

set -e
if [ "$DEBUG" ]; then
  set -x
fi

print_help() {
  echo "Usage: ./build_systemd.sh release_name [arch]"
  echo "release_name should be either 'bookworm' or 'unstable'"
}

if [ -z "$1" ]; then
  print_help
  exit 1
fi

if [ "$EUID" -ne 0 ]; then 
  echo "This script must be run as root."
  exit 1
fi

if [ "$2" ]; then
  arch="$2"
else
  arch="amd64"
fi

release_name="$1"
base_path="$(realpath $(dirname $0))"
patch_path="${base_path}/systemd_${release_name}.patch"
tmp_dir="/tmp/chromeos-systemd"
qemu_dir="$base_path/qemu"
disk_img="$qemu_dir/$release_name-$arch.img"

echo "creating build directory"
build_dir="$base_path/build"
rm -rf $build_dir || true
mkdir -p $build_dir
cd $build_dir

echo "setting up apt config"
mkdir -p $tmp_dir
cat > $tmp_dir/sources.list <<EOF
deb-src [trusted=yes] http://deb.debian.org/debian $release_name main
EOF
cat > $tmp_dir/apt.conf <<EOF
Dir::State "$tmp_dir/apt/lib/apt";
Dir::State::status "$tmp_dir/apt/var/lib/dpkg/status";
Dir::Etc::SourceList "$tmp_dir/sources.list";
Dir::Etc::SourceParts "$tmp_dir/sources.list.d";
Dir::Cache "$tmp_dir/apt/var/cache/apt";
EOF
mkdir -p $tmp_dir/apt/sources.list.d
mkdir -p $tmp_dir/apt/var/lib/apt/partial
mkdir -p $tmp_dir/apt/lib/apt/list/partial
mkdir -p $tmp_dir/apt/var/cache/apt/archives/partial
mkdir -p $tmp_dir/apt/var/lib/dpkg
touch $tmp_dir/apt/var/lib/dpkg/status

echo "downloading source package"
apt-get update -c $tmp_dir/apt.conf
apt-get source -c $tmp_dir/apt.conf -t $release_name systemd
source_dir=$(find $build_dir -mindepth 1 -maxdepth 1 -type d -printf '%f\n')

echo "applying patches"
cd $source_dir
quilt import $patch_path
quilt push

echo "setting up disk image"
mkdir -p $qemu_dir
if [ ! -f "$disk_img" ]; then
  sbuild-qemu-create --arch=$arch $release_name https://deb.debian.org/debian -o $disk_img
fi

echo "building package"
build_log="$base_path/build_$release_name_$arch.log"
sbuild-qemu --image=$disk_img --ram=4096 --cpus=$(nproc --all) --arch=$arch --no-run-piuparts --no-run-lintian