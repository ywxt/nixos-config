#!/bin/bash

set -e

sdk_root=/home/openharmony/prebuilts/ohos-sdk/linux
latest_sdk=

# Sort from oldest to newest and prepend each directory. This leaves the
# newest SDK first in PATH while retaining every installed SDK as a fallback.
while IFS= read -r toolchains; do
    PATH="$toolchains:$PATH"
    latest_sdk=${toolchains%/toolchains}
done < <(find "$sdk_root" -mindepth 2 -maxdepth 2 -type d -name toolchains -print 2>/dev/null | sort -V)

if [[ -n $latest_sdk ]]; then
    export OHOS_SDK_HOME=$latest_sdk
fi
export PATH

exec "$@"
