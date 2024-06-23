#!/bin/bash

base_path="$(realpath $(dirname $0))"
cd $base_path
. ./common.sh

print_help() {
  echo "Usage: ./build_package_chroot.sh distro_name release_name arch"
  echo "Valid named arguments (specify with 'key=value'):"
  echo "  source_type - Package source type (either git or apt)"
  echo "  pkg_source  - Package source location"
  echo "  patches     - Patch files (relative to the repo dir)"
}

assert_root
assert_args "$3"
parse_args "$@"

distro_name="$1"
release_name="$2"
arch="$3"

source_type="${args['source_type']}"
pkg_source="${args['pkg_source']}"
patches="${args['patches']}"

build_dir="$base_path/build"
source_dir="$build_dir/pkg"
host_arch="$(dpkg --print-architecture)"
repo_url="$(get_distro_info "$distro_name" | cut -d'|' -f1)"
repo_components="$(get_distro_info "$distro_name" | cut -d'|' -f2)"

#setup apt repos
rm -f /etc/apt/sources.list
echo "deb $repo_url $release_name $repo_components" >> /etc/apt/sources.list
echo "deb-src $repo_url $release_name $repo_components" >> /etc/apt/sources.list

#install debian build tools
apt-get update
apt-get upgrade -y
apt-get install git devscripts quilt equivs -y

#create a directory to put the package source in
rm -rf "$build_dir"
mkdir -p "$build_dir"
cd "$build_dir"

#download the package source
if [ "$source_type" = "git" ]; then
  git clone --depth=1 "$pkg_source" "$source_dir"

elif [ "$source_type" = "apt" ]; then
  echo "downloading source package"
  apt-get update
  apt-get source "$pkg_source"
  downloaded_dir=$(find "$build_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
  mv "$downloaded_dir" "$source_dir"

else
  echo "invalid source type"
  exit 1
fi

#apply any needed patches
cd "$source_dir"
if [ "$patches" ]; then
  for patch in "$patches"; do
    patch_path="$base_path/$patch"
    quilt import $patch_path
  done
  quilt push
fi

#install build deps
dpkg --add-architecture $arch
apt-get update
mk-build-deps --host-arch $arch
apt-get install -y ./*.deb

#build the package
export DEB_BUILD_OPTIONS=nocheck #skip tests
dpkg-buildpackage -b -rfakeroot -us -uc -a$arch