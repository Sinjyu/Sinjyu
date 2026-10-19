#!/usr/bin/env bash
#
# OpenRA 红警2 Mod（只有红警2，没有尤里的复仇）· Mac 一键安装/更新
#
#   ./install-openra.sh "/path/to/RA2 retail folder"     # 里面要有 ra2.mix / language.mix（theme.mix 是音乐，可选）
#
# 可重复执行，做过的步骤会跳过：
#   1. 克隆 OpenRA/ra2 到 $OPENRA_RA2_DIR（默认 ~/openra-ra2），锁定在已验证的提交
#   2. 打 Mod 补丁：更快的速度档、更大的缩放范围、更长的建造栏
#   3. 下载它指定的引擎 release-20231010，打引擎补丁：解除"逻辑帧不能超过渲染帧"的速度上限
#   4. 编译
#   5. 把原版素材拷到 ~/Library/Application Support/OpenRA/Content/ra2/（原版英文语音、EVA、音乐都在这里面）
#   6. 生成启动脚本 play.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${OPENRA_RA2_DIR:-$HOME/openra-ra2}"
MOD_REPO="https://github.com/OpenRA/ra2.git"
MOD_PIN="61e24e3c1d7b586aa55a86096d29e1559aa9b994"   # 2025-11-28，补丁基于此提交
MOD_PATCH="$HERE/patches/ra2-61e24e3-speed-zoom-sidebar.patch"
ENGINE_PATCH="$HERE/patches/engine-release-20231010-loop.patch"
CONTENT="$HOME/Library/Application Support/OpenRA/Content/ra2"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m错误:\033[0m %s\n' "$*" >&2; exit 1; }

RETAIL="${1:-}"
[ -n "$RETAIL" ] || die "请传入原版游戏文件夹路径，例如 ./install-openra.sh \"\$HOME/Games/RA2\""
[ -d "$RETAIL" ] || die "不是文件夹: $RETAIL"

# 大小写不敏感地找文件（Steam/光盘版文件名大小写不一）
find_retail() { find "$RETAIL" -maxdepth 1 -iname "$1" -print -quit; }

bold "1/6 检查依赖"
for c in git make curl unzip python3 dotnet patch; do
  command -v "$c" >/dev/null 2>&1 || die "缺少 ${c}（见 README『OpenRA 路线』准备工作）"
done
for f in ra2.mix language.mix; do
  [ -n "$(find_retail "$f")" ] || die "$RETAIL 里没有 $f"
done

bold "2/6 获取 OpenRA/ra2 → $WORK"
[ -d "$WORK/.git" ] || git clone "$MOD_REPO" "$WORK"
cd "$WORK"
if [ "$(git rev-parse HEAD)" != "$MOD_PIN" ]; then
  git diff --quiet || die "$WORK 有未提交改动，且不在锁定提交上；请先自行处理"
  git fetch origin && git checkout --detach "$MOD_PIN"
fi
if git apply --reverse --check "$MOD_PATCH" 2>/dev/null; then
  echo "  Mod 补丁已打过"
else
  git apply "$MOD_PATCH" && echo "  Mod 补丁 OK"
fi

bold "3/6 引擎（release-20231010）+ 速度补丁"
./fetch-engine.sh
if grep -q "MinGameplayFps" engine/OpenRA.Game/Game.cs; then
  echo "  引擎补丁已打过"
else
  patch -d engine -p1 --forward < "$ENGINE_PATCH" && echo "  引擎补丁 OK"
fi

bold "4/6 编译"
make

bold "5/6 拷贝原版素材 → $CONTENT"
mkdir -p "$CONTENT"
for f in ra2.mix language.mix theme.mix; do
  src="$(find_retail "$f")"
  if [ -z "$src" ]; then
    echo "  （没有 ${f}，跳过；theme.mix 只是音乐）"
  elif [ -f "$CONTENT/$f" ] && cmp -s "$src" "$CONTENT/$f"; then
    echo "  $f 已存在"
  else
    cp "$src" "$CONTENT/$f" && echo "  $f OK"
  fi
done

bold "6/6 启动脚本"
cat > "$WORK/play.sh" <<'EOF'
#!/usr/bin/env bash
# OpenRA 指定 .NET 6；没装 6、只装了更新版本时，让它跑在新版本运行时上。
cd "$(dirname "$0")"
if ! dotnet --list-runtimes 2>/dev/null | grep -q "Microsoft.NETCore.App 6\."; then
  export DOTNET_ROLL_FORWARD=Major
fi
exec ./launch-game.sh "$@"
EOF
chmod +x "$WORK/play.sh"

bold "完成。启动："
cat <<EOF

  $WORK/play.sh

  进游戏后：Settings → Display → Battlefield Camera 选 Far（滚轮能比原来缩得更远），
  屏幕够高时还有 Furthest（1 屏幕像素 = 1 游戏像素，最远）；
  遭遇战房间里 Game Speed 多了 Turbo / Ludicrous 两档。
EOF
