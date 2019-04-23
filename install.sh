#!/bin/sh
# Usage: PREFIX=/usr/local ./install.sh
#
# Installs node-build under $PREFIX.

set -e

cd "$(dirname "$0")"

if [ -z "${PREFIX}" ]; then
  PREFIX="/usr/local"
fi

BIN_PATH="${PREFIX}/bin"
ETC_PATH="${PREFIX}/etc"
SHARE_PATH="${PREFIX}/share/node-build"

mkdir -p "$BIN_PATH" "$ETC_PATH" "$SHARE_PATH"

install -p bin/* "$BIN_PATH"
install -d etc/* "$ETC_PATH"
install -p -m 0644 share/node-build/* "$SHARE_PATH"
