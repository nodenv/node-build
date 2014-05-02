#!/bin/bash
# Very basic script for generating version files of NodeJS releases
# NOTE: It assumes files are stores in <VERSION>/<VERSION>.tar.gz paths
#       anything else will fail and be skipped (Such as v0.10.16-isaacs-manual)
#
# Author: 3onyc <3onyc@x3tech.com>
#

set -o nounset

readonly __DIR__="$(cd "$(dirname "${0}")"; pwd)"
readonly __BASE__="$(basename "${0}")"
readonly __FILE__="${__DIR__}/${__BASE__}"

main() {
    # Get the nodejs distributions, filter for only the folders, get the folder name including /, strip the slash
    local VERSIONS=$(curl http://nodejs.org/dist/ 2>/dev/null | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+.*?/"' | cut -d'"' -f2 | sed 's#/$##')

    # Loop over the versions
    for VERSION in $VERSIONS; do
        echo "Fetching ${VERSION}"

        local URL="http://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.gz"

        # Verify existence
        HEADERS="$(curl -I -f "${URL}" 2>/dev/null)"
        local EXITCODE=$?

        if [ $EXITCODE -ne 0 ]; then
            echo "Couldn't fetch (Exit Code: ${EXITCODE})"
            echo "$HEADERS"
            continue
        fi

        # Fetch the URL, calculate the sha1sum, remove trailing dash
        local SHASUM="$(curl "${URL}" | sha1sum -b | cut -d' ' -f1)"
        echo "Hash ${SHASUM}"

        # Create/update file
        echo "install_package \"node-${VERSION}\" \"http://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.gz#${SHASUM}\"" > "$__DIR__/share/node-build/${VERSION#v}"

        # Newline after each run
        echo
    done
}

main
