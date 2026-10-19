# 红警2 / 尤里的复仇 · Mac Studio 本地版

目标机器：Mac Studio M4 Max，macOS 26.6.2 (25G83)。界面用原版英文，语音、EVA 播报、音乐都用**你自己正版文件里的原版英文音频**。

本目录是唯一入口：

| 文件 | 用途 |
|---|---|
| `README.md` | 本文 |
| `install.sh` + `patches/` + `tools/sim/` | 路线 A（Chrono Divide 引擎，**含尤里的复仇**） |
| `openra/install-openra.sh` + `openra/patches/` + `openra/tools/loopsim/` | 路线 B（OpenRA 红警2 Mod，**只有红警2**） |
| `tools/merge_csf_zh.py` | 路线 A 的可选汉化（默认不用） |

---

## 0. 先说结论：选哪条路

- **红警2没有官方 Mac 版。** EA 2025 年开源的是 C&C、红警1、叛逆者、将军，不包括红警2。
- **更正**：你补充的原文说明，作者走的是 **OpenRA + GitHub 上的红警2 Mod**（[OpenRA/ra2](https://github.com/OpenRA/ra2)）。我上一版推测"他用的是 Chrono Divide 引擎"，**这个推测是错的**。这一版按 OpenRA 的代码重新核对了他说的四个问题（第 3 节），每一个都在代码里找到了对应的位置。
- 两条路线都要用到你自己的正版游戏文件（第 1 节），仓库里不含任何游戏素材。

| | A. Chrono Divide 引擎（ammaar 的移植） | B. OpenRA 红警2 Mod（原文作者的路线） |
|---|---|---|
| 尤里的复仇 | ✅ 有 | ❌ **没有**，只有红警2本体（阵营只有盟军和苏联各国） |
| 运行方式 | 本地服务器 + 浏览器 | 原生 Mac 程序（SDL2 + OpenGL） |
| 原版英文语音 / EVA / 音乐 | ✅ 从你的文件导入 | ✅ 直接读你的 `ra2.mix` / `language.mix` / `theme.mix` |
| 完成度 | 遭遇战（skirmish）可玩；战役只在另一个分支 LEBRUNtho 里，而且是 alpha，本方案没接 | 作者在主菜单写明是 **pre-alpha**："Many features are missing or incomplete, performance has not been optimized" |
| 缩放 / 建造栏 / 速度 | 补丁处理（第 2 节） | 补丁处理（第 3 节） |
| 依赖 | Xcode 命令行工具、Homebrew、ffmpeg、bun | Xcode 命令行工具、.NET 8 SDK |

**建议**：你最初要的是尤里的复仇，所以优先选 **A**。想要原生 App 的体验、又能接受只有红警2，就选 **B**。两条路线互不影响，可以都装。

其他选择：[chronodivide.com](https://chronodivide.com) 可以直接在浏览器里玩，但没法改代码（它现在支不支持单机/AI，我没有核实）。原版 exe 配 CrossOver/Wine 能保留 100% 原版手感，但原版本身没有缩放功能，而且我这次没有在 macOS 26 上验证。**不建议**用国内"Mac 移植版"下载站，那些是来源不明的封装包。

---

## 1. 下载正版游戏文件（两条路线共用）

Steam 上的 **Command & Conquer: Red Alert 2 and Yuri's Revenge**（App ID **2229850**，两部打包卖）是 Windows 版，Mac 版 Steam 客户端不让你装。用 Valve 官方的 SteamCMD 可以强制下载 Windows 版文件：

```bash
# 直接从 Valve 下载（Homebrew 的 steamcmd cask 也只是下载同一个文件）
mkdir -p ~/steamcmd && cd ~/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf -

# 把 YOUR_STEAM_NAME 换成你的 Steam 登录名（不是昵称），整段一起粘贴
./steamcmd.sh +@sSteamCmdForcePlatformType windows \
              +force_install_dir "$HOME/Games/RA2" \
              +login YOUR_STEAM_NAME \
              +app_update 2229850 validate +quit
```

- 第一次运行会先自我更新，花几分钟，这是正常的。
- 如果提示需要 Rosetta，运行 `softwareupdate --install-rosetta --agree-to-license` 后再跑一次（我没核实这个 macOS 版是不是 Intel 程序，所以写成条件）。
- `brew install --cask steamcmd` 也行，但它在某些机器上会报 `undefined method 'first' for nil`（Homebrew 自身的问题，见下面的说明），直接下载最省事。

- 账号里必须**已经买了**这款游戏。过程中会要求输入密码和 Steam Guard 验证码。
- 如果 macOS 拦截 `Breakpad.framework`，或者报 `Failed to load steamconsole.dylib`：去「系统设置 → 隐私与安全性」点"仍要打开"，然后再跑一次。
- 下完后检查文件：路线 B 需要 `ra2.mix`、`language.mix`（原版语音在里面），`theme.mix`（音乐）可选；路线 A 还需要 `multi.mix`，以及尤里的复仇的 `ra2md.mix`、`langmd.mix`。
- 光盘版或 Windows 电脑上装好的目录也可以，整个文件夹拷过来即可。
- 关于 `brew install --cask steamcmd` 报 `undefined method 'first' for nil`：错误出在 Homebrew 解析在线 cask 数据的代码里（`cask_loader.rb` 的 `FromAPILoader`），跟 SteamCMD 本身无关。我**推测**是本机 Homebrew 版本落后于在线 cask 数据（steamcmd 的 cask 用了较新的写法），没有找到对应的官方 issue。想修 Homebrew 可以试 `brew update`，不行再 `brew update-reset`。

---

## 2. 路线 A：Chrono Divide 引擎（含尤里的复仇）

### 准备（一次性）

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"   # 已装 Homebrew 就跳过
brew install ffmpeg
curl -fsSL https://bun.sh/install | bash      # 装完重开终端
```

### 安装与启动

```bash
git clone -b claude/red-alert-2-mac-config-83tqt5 https://github.com/sinjyu/sinjyu.git
cd sinjyu/ra2-mac
./install.sh "$HOME/Games/RA2"
cd ~/ra2-mac-port/redalert2 && RA2_HTTP=1 bun run dev:bun
```

用 `dev:bun` 而不用 `dev`：工程的 `dev` 用的是系统里的 Node 来跑 Vite，而 Vite 8 要求 Node 20.19 以上。Mac 上常见的旧版 Node（比如 18）会直接报 `CustomEvent is not defined`。`dev:bun` 改用 bun 来跑，不依赖 Node 的版本。

然后用浏览器打开 **http://localhost:4000/?shell=1**（先用 Chrome，不行再换 Safari，两种我都没在真机上测过）。

- `install.sh` 会克隆 [ammaarreshi/RedAlert2-Mac-iOS-iPad](https://github.com/ammaarreshi/RedAlert2-Mac-iOS-iPad)，锁定在提交 `991945d`，打上补丁，再从你的文件导入素材。可以重复执行，做过的步骤会跳过。默认是英文界面；想要中文就用 `RA2_ZH=1 ./install.sh ...`。
- 想比"最快"档还快：在网址后加 `&turbo=1.5`（可以设 1–4 倍）。
- 「Options → Resolution」里选 2560×1440 或 2560×1600 能让建造栏更长，直接全屏也可以。
- 开发服务器监听 `0.0.0.0`，同一局域网里的其他设备也能访问 4000 端口。

### 改了什么（代码位置基于 `991945d`）

| 问题 | 原因 | 处理 |
|---|---|---|
| 缩放 | ammaar 的版本已经支持滚轮缩放，范围从"整张地图刚好装满屏幕"到 2 倍（`CameraZoom.ts`） | 不用改 |
| 建造栏短 | 行数按画面高度算（`Hud.ts`）。默认分辨率 1024×768，桌面版最高只能选 1920×1080 | `Resolution.tsx` 里加了 2560×1600、2560×1440、1920×1200 |
| 最快也慢 | `GameScreen.ts` 每帧只给模拟 8ms 预算，超出的 tick 会**直接丢掉**。单个 tick 超过约 8ms、帧率又掉下来时，速度就跟着帧率掉（30fps 时只剩 50%） | 预算改成 33ms；另外加了 `?turbo=` 参数 |

模拟结果（`tools/sim/run.sh`，驱动的是引擎原样的 `GameAnimationLoop.ts`，目标 60 tick/s）：

| 显示器 | 单 tick 耗时 | 渲染耗时 | 原版 | 补丁后 |
|---|---|---|---|---|
| 60Hz | 2ms | 4ms | 100% | 100% |
| 60Hz | 10ms | 8ms | **50%** | **100%** |
| 60Hz | 12ms | 10ms | **50%** | **100%** |
| 120Hz | 12ms | 10ms | 67% | **100%** |
| 60Hz | 20ms | 10ms | 50% | 50%（机器确实跟不上） |

**自测速度**：最快档下每个 tick 让游戏时钟走 1/15 秒，所以用秒表计时 30 秒，右侧栏的游戏时钟应该走过 **2:00**。

---

## 3. 路线 B：OpenRA 红警2 Mod（原文作者的路线，只有红警2）

### 准备（一次性）

```bash
xcode-select --install     # 提供 git、make、python3
```

再装 **.NET 8 SDK（Arm64 版）**：用微软官网 dotnet.microsoft.com 的 macOS Arm64 安装包。

不需要 Homebrew 装 sdl2 / openal-soft / freetype（网上旧教程会让你装）。这个引擎版本用到的 SDL2、FreeType、OpenAL、Lua 都来自 NuGet 包，包里自带 `osx-arm64` 原生库，编译时会自动下载。

### 安装与启动

```bash
cd sinjyu/ra2-mac/openra
./install-openra.sh "$HOME/Games/RA2"
~/openra-ra2/play.sh
```

`install-openra.sh` 做的事（可重复执行，做过的步骤会跳过）：

1. 克隆 [OpenRA/ra2](https://github.com/OpenRA/ra2)，锁定在提交 `61e24e3`（2025-11-28）
2. 打 Mod 补丁
3. 下载它指定的引擎 `release-20231010`，打引擎补丁
4. 编译
5. 把 `ra2.mix`、`language.mix`、`theme.mix` 拷到 `~/Library/Application Support/OpenRA/Content/ra2/`。这就是原文说的"自己找原版安装包，把素材替换进去"那一步：Mod 自带的安装器只认光盘和 Windows 注册表，在 Mac 上用不了
6. 生成 `play.sh`。OpenRA 这个版本指定用 .NET 6（已停止支持），没装 6 时，`play.sh` 会设置 `DOTNET_ROLL_FORWARD=Major`，让它跑在 .NET 8 上

### 原文四个问题在 OpenRA 里的原因和处理

代码位置基于引擎 `release-20231010`、Mod `61e24e3`。

| 问题 | 代码里的原因 | 处理 |
|---|---|---|
| **视角不能缩放** | 滚轮能缩放，但"最远能缩多远"由设置里的 *Battlefield Camera* 档位决定。最远的 Far 档只允许屏幕显示 900–1300 游戏像素高（引擎默认值，在 `WorldViewportSizes.cs`）；Mod 没有改过这个值 | Mod 补丁在 `mod.yaml` 加了 `WorldViewportSizes: FarWindowHeights: 1200, 1800`。进游戏后选 Settings → Display → Battlefield Camera → **Far**。屏幕够高时还有 **Furthest**（1 屏幕像素 = 1 游戏像素） |
| **建造菜单长度不对** | `chrome/ingame-player.yaml` 里 `ProductionPalette` 写死了 `MaximumRows: 6`（引擎默认是不限）。引擎本身会按屏幕高度限制行数（`ClassicProductionLogic.cs`） | 改成 `MaximumRows: 12`，实际行数仍受屏幕高度限制。背景条是逐行复制的，会跟着变长 |
| **没有中文** | 这个引擎版本的界面文字大多直接写在 yaml 里；默认字体 FreeSans 没有汉字，我用引擎的 FreeType 代码实测，每个汉字都渲染成同一个方框 | **你说英文就行，所以不处理** |
| **最快也慢得离谱**（原文："引擎里某个渲染逻辑把速度上限给卡死了"） | `Game.cs` 主循环里，正常对局每跑完一个逻辑 tick，就设 `renderBeforeNextTick = true`，强制先渲染一帧才能跑下一个 tick。结果是**逻辑速度永远超不过帧率**。默认又开着 VSync（`Settings.cs` 里 `VSync = true`），60Hz 屏幕上一帧只要超过 16.7ms，就掉到 30fps，也就只剩 30 tick/s。最快档是 `Timestep: 20`，也就是 50 tick/s，这时只剩 60% 速度。这段逻辑一直保留到 2026-10 的最新开发版（bleed） | 引擎补丁：只有距离上次渲染超过 33ms 才强制渲染，其余时间 tick 可以连着跑。Mod 补丁另外加了两个速度档：**Turbo**（16ms，约等于原版"最快"的 60fps）和 **Ludicrous**（10ms，100 tick/s） |

速度模拟（`openra/tools/loopsim/run.sh`：用 C# 照搬 `Game.cs` 主循环的时序逻辑，换成虚拟时钟，VSync 按"等到下一次刷新"建模）：

| 速度档 | 单 tick | 渲染 | VSync | 原版 | 补丁后 |
|---|---|---|---|---|---|
| fastest (50/s) | 2ms | 5ms | 60Hz | 100% | 100% |
| fastest | 3ms | 12ms | 60Hz | 100% | 100% |
| fastest | 4ms | 18ms | 60Hz | **60%** | **100%**（30fps） |
| fastest | 4ms | 25ms | 关 | 69% | **100%** |
| fastest | 6ms | 35ms | 60Hz | **40%** | **100%**（15fps） |
| Turbo (62.5/s) | 4ms | 18ms | 60Hz | 48% | **100%** |
| Ludicrous (100/s) | 3ms | 12ms | 60Hz | 60%（被 VSync 卡在 60/s） | **100%** |
| fastest | 15ms | 10ms | 60Hz | 60% | 89% |

代价是渲染太慢时帧率会降（表里括号是帧率），但游戏速度不再跟着掉。

### 验证过什么（在 Linux 上，用 .NET 8 SDK）

- 原版 Mod 和打补丁后的 Mod 都能编译。
- OpenRA 自带的 `utility.sh --check-yaml` 在补丁前后都零报错。我故意把速度档的语言键写错，它能报出来，说明这项检查确实生效。
- 写了个小程序，用引擎自己的 `FieldLoader` 读取 `mod.yaml`，确认 `FarWindowHeights` 读到的是 1200,1800（原版没有这一段时，用的是默认值 900,1300）。
- 补丁后的 `Game.cs` 在引擎最严格的代码分析下没有任何报错；其他 201 个报错是新版 SDK 对老文件的风格提示，原本就有。
- `install-openra.sh` 连跑两次：第一次补丁、编译、拷贝全部完成，第二次各步正确跳过。用的是假的游戏文件，而且因为这个环境下载不了 GitHub 的 zip 包，引擎换成了同一个 tag 的 git 克隆。

---

## 4. 没验证的地方（请当作风险）

- **两条路线都没在 Mac 真机上跑过**：这个环境是 Linux，没有显示器，也没有游戏素材。上面列的验证都是编译、规则检查、代码级模拟。
- 原文作者具体改了哪些地方，我看不到；OpenRA 的四个对应点是我读代码找到的，和他描述的现象吻合，但**不能确认就是他改的那几处**。
- OpenRA Mod 的单位语音表里有作者自己标注的临时占位（`voices.yaml`："gotta put something as temp else game crashes"），个别死亡音效不是正确的那一条。这是 Mod 本身的问题。
- `DOTNET_ROLL_FORWARD=Major`（让 .NET 6 程序跑在 .NET 8 上）我只用规则检查工具验证过能运行，没跑过完整游戏。如果游戏启动报错，就装 .NET 6 运行时（微软存档页面还能下载），`play.sh` 检测到 6 就不会再设这个变量。
- M4 Max 很快，正常对局里两条路线的原版可能本来就能满速。补丁保证的是大地图、后期、高分辨率时不掉速。
- 授权：路线 A 的引擎作者没有开源，授权链条无法核实；路线 B 是 GPL-3.0。**两条都只限个人、非商业使用**，不要分发打包好的版本。

## 5. 来源和版本锁定

| 内容 | 来源 | 锁定版本 |
|---|---|---|
| 路线 A 移植工程 | https://github.com/ammaarreshi/RedAlert2-Mac-iOS-iPad | `991945d60a7139d3c4c438326abb6d3c093b2497`（2026-08-08） |
| 路线 A 补丁 | `patches/ammaar-991945d-mac-fixes.patch` | 4 个文件，+28 / −3 行 |
| 路线 B Mod | https://github.com/OpenRA/ra2 | `61e24e3c1d7b586aa55a86096d29e1559aa9b994`（2025-11-28） |
| 路线 B 引擎 | https://github.com/OpenRA/OpenRA | `release-20231010`（由 Mod 的 `mod.config` 指定） |
| 路线 B 补丁 | `openra/patches/ra2-61e24e3-speed-zoom-sidebar.patch`、`openra/patches/engine-release-20231010-loop.patch` | Mod 3 个文件 +19 / −1 行；引擎 1 个文件 +11 / −1 行 |
| 可选中文表（路线 A） | https://github.com/huangkaoya/redalert2 `public/general.csf` | `898d89188542a3028a232031ce1a0bdc7c605b6f` |
| SteamCMD | https://developer.valvesoftware.com/wiki/SteamCMD | — |
| 游戏 | Steam App 2229850 | — |

升级任一工程时，先改脚本里的锁定版本（`PORT_PIN` / `MOD_PIN`），再看补丁能不能打上；打不上就重新做补丁，不要硬打。
