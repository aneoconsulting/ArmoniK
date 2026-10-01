#!/bin/sh
# Reads rendered manifests on stdin and fails when an image does not come from the registry given as
# $1: the image fields, and the flags passing an image reference to an operator (config reloader...).
set -eu

registry="$1"

images="$(
  sed -n \
    -e 's/^[[:space:]]*\(- \)\{0,1\}image:[[:space:]]*"\{0,1\}\([^"[:space:]]*\)"\{0,1\}.*/\2/p' \
    -e 's/.*--[a-z.-]*=\([a-z0-9.-]*\.[a-z][a-z]*\(:[0-9][0-9]*\)\{0,1\}\/[^[:space:]",]*:[^[:space:]",]*\).*/\1/p' |
    sort -u
)"

outside="$(printf '%s\n' "$images" | grep -v -e "^${registry}/" -e '^$' || true)"
if [ -n "$outside" ]; then
  echo "Images outside ${registry}:"
  printf '%s\n' "$outside"
  exit 1
fi
echo "$(printf '%s\n' "$images" | grep -c .) images, all from ${registry}"
