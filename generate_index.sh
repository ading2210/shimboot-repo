#!/bin/bash

#generate index html files for the deployment

set -e
if [ "$DEBUG" ]; then
  set -x
fi

shopt -s globstar

base_path="$(realpath $(pwd))"
website_base="$base_path/website"
website_dirs="$(ls -d $website_base/**/)"

for web_dir in $website_dirs; do
  if [ -f "$web_dir/index.html" ]; then
    continue
  fi

  rel_path="/$(realpath --relative-to="${website_base}" "$web_dir")/"
  ls_out="$(ls -l $web_dir)"
  echo "<!DOCTYPE html>
    <html>
      <head>
        <title>Index of $rel_path</title>
      </head>
      <body>
        <h1>Index of $rel_path</h1>
        <hr>
        <pre>$ls_out</pre>
        <hr>
      </body>
    </html>
  " > "$web_dir/index.html"
done