#!/usr/bin/env bash
#
# 红警2 + 尤里的复仇 · Mac 本地版 一键安装/更新
#
#   ./install.sh "/path/to/RA2 retail folder"     # 文件夹里要有 ra2.mix / ra2md.mix
#
# 做的事（可重复执行，已做过的步骤会跳过）：
#   1. 克隆 ammaarreshi/RedAlert2-Mac-iOS-iPad 到 $RA2_WORKDIR（默认 ~/ra2-mac-port），锁定到已验证的提交
#   2. 打上 patches/ 里的补丁（速度、分辨率/侧边栏、turbo）
#   3. 运行它自带的 scripts/setup.sh，从你的正版文件导入素材（不联网下载任何游戏素材）
#   4. （可选，RA2_ZH=1 时）下载 huangkaoya/redalert2 的中文字符串表，与你的英文 YR 表合并 → 中文界面
#      默认保持原版英文界面；语音一直是原版英文
#   5. 打印启动命令
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${RA2_WORKDIR:-$HOME/ra2-mac-port}"
PORT_REPO="https://github.com/ammaarreshi/RedAlert2-Mac-iOS-iPad.git"
PORT_PIN="991945d60a7139d3c4c438326abb6d3c093b2497"   # 2026-08-08，补丁基于此提交
ZH_CSF_URL="https://raw.githubusercontent.com/huangkaoya/redalert2/898d89188542a3028a232031ce1a0bdc7c605b6f/public/general.csf"
PATCH="$HERE/patches/ammaar-991945d-mac-fixes.patch"
GLOSSARY="$HERE/yr_zh_glossary.tsv"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m错误:\033[0m %s\n' "$*" >&2; exit 1; }

RETAIL="${1:-}"
[ -n "$RETAIL" ] || die "请传入原版游戏文件夹路径，例如 ./install.sh \"\$HOME/Games/RA2\""
[ -d "$RETAIL" ] || die "不是文件夹: $RETAIL"

bold "1/5 检查依赖"
for c in git bun ffmpeg python3 curl; do
  command -v "$c" >/dev/null 2>&1 || die "缺少 ${c}（见 README『准备工作』）"
done

bold "2/5 获取移植工程 → $WORK"
if [ ! -d "$WORK/.git" ]; then
  git clone "$PORT_REPO" "$WORK"
fi
cd "$WORK"
if [ "$(git rev-parse HEAD)" != "$PORT_PIN" ]; then
  git diff --quiet || die "$WORK 有未提交改动，且不在锁定提交上；请先自行处理"
  git fetch origin && git checkout --detach "$PORT_PIN"
fi

bold "3/5 打补丁"
if git apply --reverse --check "$PATCH" 2>/dev/null; then
  echo "  已打过，跳过"
else
  git apply --check "$PATCH" || die "补丁无法应用（工程被改过？）"
  git apply "$PATCH"
  echo "  OK"
fi

bold "4/5 从你的正版文件导入素材（几分钟）"
if [ -f "$WORK/gameres-export/manifest.json" ] && [ -z "${RA2_REIMPORT:-}" ]; then
  echo "  已导入过，跳过（要重新导入：RA2_REIMPORT=1 ./install.sh ...）"
else
  ./scripts/setup.sh "$RETAIL"
fi

bold "5/5 中文字符串表（可选）"
EN_CSF="$WORK/redalert2/public/generalmd.csf"
if [ -z "${RA2_ZH:-}" ]; then
  echo "  跳过，保持英文界面（要中文：RA2_ZH=1 ./install.sh ...）"
elif [ ! -f "$EN_CSF" ]; then
  echo "  没找到 ${EN_CSF}（你的文件里没有 langmd.mix？）→ 跳过汉化，界面保持英文"
else
  mkdir -p "$WORK/zh"
  [ -f "$WORK/zh/general.csf" ] || curl -fL "$ZH_CSF_URL" -o "$WORK/zh/general.csf"
  python3 -I "$HERE/tools/merge_csf_zh.py" \
    --en "$EN_CSF" --zh "$WORK/zh/general.csf" --glossary "$GLOSSARY" \
    --out "$WORK/redalert2/public/generalmd.zh.csf" --config "$WORK/redalert2/public/config.ini"
fi

bold "完成。启动："
cat <<EOF

  cd "$WORK/redalert2" && RA2_HTTP=1 bun run dev:bun
  然后用浏览器打开  http://localhost:4000/?shell=1
  想比"最快"还快：  http://localhost:4000/?shell=1&turbo=1.5   (1~4 倍，仅改节奏)

  （如果开了 RA2_ZH=1）未翻译的尤里条目在：${GLOSSARY}，填好第三列后重跑本脚本。
EOF
