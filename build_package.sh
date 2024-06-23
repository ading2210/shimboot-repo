#!/bin/bash

base_path="$(realpath $(dirname $0))"
cd $base_path
. ./common.sh

#this script creates a chroot then invokes build_package_chroot.sh inside the chroot

print_help() {
  echo "Usage: ./build_package.sh distro_name release_name arch"
  echo "Valid named arguments (specify with 'key=value'):"
  echo "  source_type - Package source type (either git or apt)"
  echo "  pkg_source  - Package source location"
  echo "  patches     - Patch files (relative to the repo dir)"
}

assert_root
assert_deps "debootstrap"
assert_args "$3"

distro_name="$1"
release_name="$2"
arch="$3"
repo_url="$(get_distro_info "$distro_name" "$arch" | cut -d'|' -f1)"

base_path="$(realpath $(dirname $0))"
chroot_path="$base_path/chroots/${distro_name}_${release_name}_${arch}"

#create the chroot if it doesn't exist
if [ ! -d "$chroot_path/opt/repo" ]; then
  mkdir -p $chroot_path
  debootstrap --arch $arch "$release_name" "$chroot_path" "$repo_url" || (cat "$chroot_path/debootstrap/debootstrap.log" && exit 1)
fi

#define the bind mount points
chroot_mounts="proc sys dev run"
repo_path="$chroot_path/opt/repo"

#set up a handler to unmount once we're done
unmount_all() {
  for mountpoint in $chroot_mounts; do
    umount -l "$chroot_path/$mountpoint"
  done
  umount -l "$repo_path"
}
trap unmount_all EXIT

#bind mount everything
for mountpoint in $chroot_mounts; do
  mount --make-rslave --rbind "/${mountpoint}" "${chroot_path}/$mountpoint"
done
mkdir -p "$repo_path"
mount --bind "$base_path" "$repo_path"

#run the chroot
rm -f "$chroot_path/etc/resolv.conf"
cp /etc/resolv.conf "$chroot_path/etc/resolv.conf"
LC_ALL=C chroot "$chroot_path" /usr/bin/env IN_CHROOT=1 DEBUG=$DEBUG /opt/repo/build_package_chroot.sh "$@"
