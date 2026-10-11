#!/usr/bin/env bash
# 复现 README『OpenRA 速度』一节的数字。需要 .NET SDK 8+。
set -euo pipefail
cd "$(dirname "$0")"
dotnet build -c Release -nologo -v q >/dev/null
for m in original patched; do
  for c in "20 2 5 60" "20 3 12 60" "20 4 18 60" "20 4 25 60" "20 4 25 0" "20 6 35 60" "16 4 18 60" "10 3 12 60" "20 15 10 60"; do
    dotnet bin/Release/net8.0/loopsim.dll $m $c
  done
done
