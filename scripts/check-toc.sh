#!/usr/bin/env bash
# Fails if the .toc lists a missing file, or a .lua file in the repo isn't listed in the .toc.
set -euo pipefail
cd "$(dirname "$0")/.."
toc=BeastBond.toc
status=0

listed=$(tr -d '\r' < "$toc" | grep -vE '^\s*(##|$)' | tr '\\' '/')
for f in $listed; do
    [ -f "$f" ] || { echo "toc lists missing file: $f"; status=1; }
done

for f in $(find . -name '*.lua' -not -path './.git/*' -not -path './.release/*' -not -path './dist/*' | sed 's#^\./##'); do
    echo "$listed" | grep -qxF "$f" || { echo "lua file not in toc: $f"; status=1; }
done

[ $status -eq 0 ] && echo "toc ok"
exit $status
