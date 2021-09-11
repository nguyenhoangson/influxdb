#!/usr/bin/env bash
set -exo pipefail

declare -r GOTESTSUM_VERSION=1.7.0
declare -r GOTESTSUM_URL=https://github.com/gotestyourself/gotestsum/releases/download/v${GOTESTSUM_VERSION}/gotestsum_${GOTESTSUM_VERSION}_linux_amd64.tar.gz

function main () {
    if [[ $# != 1 ]]; then
        >&2 echo Usage: $0 '<output-dir>'
        exit 1
    fi
    if [[ $(go env GOOS) != linux || $(go env GOARCH) != amd64 ]]; then
        >&2 echo Race tests only supported on linux/amd64
        exit 1
    fi

    local -r out_dir="$1"
    rm -rf "$out_dir"
    mkdir -p "$out_dir"

    # Install gotestsum.
    curl -L "${GOTESTSUM_URL}" | tar xz -C /go/bin/

    # Get list of packages to test on this node according to Circle's timings.
    local -r test_packages="$(go list ./... | circleci tests split --split-by=timings --timings-type=classname)"

    # Run tests
    local -r tags=osuergo,netgo,sqlite_foreign_keys,sqlite_json
    gotestsum --junitfile "${out_dir}/report.xml" -- -tags "$tags" -race ${test_packages[@]}
}

main ${@}
