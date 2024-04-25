#!/bin/bash

#create a new debian repo with packages from previous artifact

set -e
if [ "$DEBUG" ]; then
  set -x
fi

supported_releases="bookworm unstable"
base_path="$(realpath $(pwd))"
repo_dir="$base_path/repo/"
download_dir="$base_path/download/"

rm -rf $repo_dir || true
mkdir -p $repo_dir

for release_name in $supported_releases; do
  cd $base_path

  pool_dir="$repo_dir/pool/main/$release_name"
  dists_dir="$repo_dir/dists/$release_name/main/binary-amd64"
  mkdir -p $dists_dir
  mkdir -p $pool_dir
  cp $download_dir/systemd_$release_name/*.deb $pool_dir
  cp $download_dir/mesa_generic/*.deb $pool_dir
  rm $pool_dir/*dbgsym*

  cd $repo_dir
  dpkg-scanpackages --arch amd64 pool/main/$release_name > $dists_dir/Packages
  cat $dists_dir/Packages | gzip -9 > $dists_dir/Packages.gz
done