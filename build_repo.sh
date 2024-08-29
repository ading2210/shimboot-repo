#!/bin/bash

#create a new debian repo with packages from previous artifact

set -e
if [ "$DEBUG" ]; then
  set -x
fi

supported_releases="bookworm unstable noble"
supported_arches="amd64 arm64"
base_path="$(realpath $(pwd))"
repo_dir="$base_path/repo"
download_dir="$base_path/download"

ls -R "$download_dir"

rm -rf $repo_dir || true
mkdir -p $repo_dir

for release_name in $supported_releases; do
  for arch in $supported_arches; do
    cd $base_path

    if [ ! -d "$download_dir/${release_name}_${arch}/" ]; then
      echo "skipping ${release_name} ${arch}, no packages found"
      continue
    fi

    pool_dir="$repo_dir/pool/main/$release_name"
    dists_dir="$repo_dir/dists/$release_name/main/binary-$arch"
    mkdir -p $dists_dir
    mkdir -p $pool_dir
    cp "$download_dir/${release_name}_${arch}/"*.deb $pool_dir
    rm $pool_dir/*dbgsym* || true
    rm $pool_dir/*udev* || true

    cd $repo_dir
    dpkg-scanpackages --arch $arch pool/main/$release_name > $dists_dir/Packages
    cat $dists_dir/Packages | gzip -9 > $dists_dir/Packages.gz
  done
done