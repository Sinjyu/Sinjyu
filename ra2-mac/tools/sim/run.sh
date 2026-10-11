#!/usr/bin/env bash
# 复现 README『速度』一节的模拟结果。用法：
#   ./run.sh ~/ra2-mac-port/redalert2/src/engine/GameAnimationLoop.ts
# 需要 Node 22+。只替换该文件的两个 import 为空实现，循环逻辑原样使用。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${1:?path to GameAnimationLoop.ts}"
TMP="$(mktemp -d)"
sed -e 's#^import { IrcConnection }.*#class IrcConnection { static SocketError = class extends Error {} }#' \
    -e 's#^import { recordGamePerformanceFrame }.*#function recordGamePerformanceFrame(_t: number) {}#' \
    "$SRC" > "$TMP/loop.ts"
cp "$HERE/harness.ts" "$TMP/harness.ts"
for budget in 8 33; do
  for args in "60 2 4" "60 3 20" "60 9 6" "60 10 8" "60 12 10" "60 14 12" "120 12 10" "60 20 10"; do
    set -- $args
    node --experimental-strip-types --no-warnings "$TMP/harness.ts" "$TMP/loop.ts" "$1" "$2" "$3" "$budget"
  done
done
rm -rf "$TMP"
