# 红警2 + 尤里的复仇 · Mac Studio 本地版

目标机器：Mac Studio M4 Max，macOS 26.6.2 (25G83)。
本目录就是唯一入口：`README.md`（本文）+ `install.sh`（一键安装）+ `patches/`（引擎补丁）+ `tools/`（汉化合并、速度模拟）+ `yr_zh_glossary.tsv`（尤里条目翻译表，第一次运行后生成）。

---

## 0. 先说结论

- **红警2没有官方 Mac 版。** EA 在 2025 年开源了 C&C、红警1、叛逆者、将军，**不包括红警2**，所以没有官方源码能直接编译。
- 你引用的那段经历，从症状看用的是 **Chrono Divide 引擎**（一个用 TypeScript 从零重写的红警2引擎，跑在浏览器 / WebView 里）这一系的开源移植。我**没找到那篇原文**，所以它具体用的是哪个仓库、改了哪些地方，**只是推测**（理由见第 5 节）。
- 我选的路线：`ammaarreshi/RedAlert2-Mac-iOS-iPad`（带尤里的复仇、已经支持缩放）+ 本目录的补丁 + 用 `huangkaoya/redalert2` 的中文字符串表做汉化。**素材来自你自己的正版游戏文件**，仓库里不含任何游戏素材。

| 路线 | 适合 | 缩放 | 中文 | 速度 | 代价 |
|---|---|---|---|---|---|
| **A. 本方案**（Chrono Divide 引擎 + 补丁） | 想要本地、可改的版本 | ✅ 引擎自带 | ✅ 本方案合并 | ✅ 打补丁后 | 需要命令行，约 30–60 分钟 |
| B. [chronodivide.com](https://chronodivide.com) 直接在浏览器玩 | 只想快速玩一局 | 看官方 | 看官方 | 看官方 | 改不了代码；以联机为主（我没核实它现在的单机/AI 支持情况） |
| C. 原版 exe + CrossOver / Wine | 想要 100% 原版手感 | ❌ 原版没有这个功能 | 要中文版的原始文件 | 正常 | CrossOver 收费；**这次没有在 macOS 26 上验证** |

**不建议**用国内"Mac 移植版"下载站（macgf、macat、各类 "for mac 破解"）。那些通常是来源不明的 Wine 封装包，版权和安全都没法核实。

---

## 1. 下载正版游戏文件（Steam 版，用 SteamCMD 在 Mac 上下）

Steam 商店里的 **Command & Conquer: Red Alert 2 and Yuri's Revenge**（App ID **2229850**，两部打包销售）是 Windows 版，Mac 上的 Steam 客户端不会让你安装它。用 Valve 官方的命令行工具 SteamCMD 可以强制下载 Windows 版的文件：

```bash
brew install --cask steamcmd
steamcmd +@sSteamCmdForcePlatformType windows \
         +force_install_dir "$HOME/Games/RA2" \
         +login 你的Steam用户名 \
         +app_update 2229850 validate +quit
```

- 会提示输入密码和 Steam 令牌验证码（Steam Guard）。账号里必须**已经买了**这款游戏。
- 如果 macOS 拦截 SteamCMD 自带的 `Breakpad.framework`，或者报 `Failed to load steamconsole.dylib`，去「系统设置 → 隐私与安全性」点"仍要打开"，然后再跑一次。
- 下完后检查 `~/Games/RA2` 里有没有 `ra2.mix`、`language.mix`、`multi.mix`、`ra2md.mix`、`langmd.mix`（最后两个是尤里的复仇的文件）。
- 已有其他来源的正版文件（光盘、Windows 电脑上 Steam / EA App 装好的目录），直接把整个文件夹拷过来也可以。
- Steam 版自带哪些语言我**没查到确切信息**，可以看商店页确认。本方案的中文不依赖它。

## 2. 准备工作（一次性）

```bash
xcode-select --install                 # 命令行工具，自带 git 和 python3
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"   # 已装 Homebrew 就跳过
brew install ffmpeg                    # 用来转换音乐和视频
curl -fsSL https://bun.sh/install | bash   # JS 运行时；装完重开一个终端窗口
```

浏览器：上游推荐 Chrome / Edge，ammaar 的版本主要针对 WebKit（Safari 用的内核）调过。**两种我都没在真机上测过**，建议先用 Chrome，不行再换 Safari。

## 3. 安装

```bash
git clone -b claude/red-alert-2-mac-config-83tqt5 https://github.com/sinjyu/sinjyu.git
cd sinjyu/ra2-mac
./install.sh "$HOME/Games/RA2"
```

`install.sh` 的具体步骤（可以重复执行，已经完成的步骤会跳过）：

1. 检查 git、bun、ffmpeg、python3、curl 是否都装了
2. 把 ammaar 的工程克隆到 `~/ra2-mac-port`（可以用 `RA2_WORKDIR` 改位置），并固定在补丁对应的那个提交 `991945d`
3. 打上 `patches/ammaar-991945d-mac-fixes.patch`
4. 运行工程自带的 `scripts/setup.sh`，从你的游戏文件导入素材，要几分钟（**不会从网上下载任何游戏素材**）
5. 下载 huangkaoya 的中文表（同样固定到某个提交），和你的英文尤里表合并，再把 `config.ini` 改成指向合并后的中文表

## 4. 启动

```bash
cd ~/ra2-mac-port/redalert2 && RA2_HTTP=1 bun run dev
```

然后用浏览器打开 **http://localhost:4000/?shell=1**

- 想比"最快"档还快：`http://localhost:4000/?shell=1&turbo=1.5`（倍数 1–4，见第 5 节）
- 进游戏后在「选项 → 分辨率」里选 **2560×1440** 或 **2560×1600**（这两个是补丁新加的；比浏览器窗口大的分辨率会自动隐藏），或者直接全屏。
- 注意：开发服务器监听的是 `0.0.0.0`，同一局域网里的其他设备也能访问 4000 端口。

---

## 5. 原文作者遇到的四个问题：原因和处理

以下"原因"都是我读代码找到的，文件位置基于 ammaar 的提交 `991945d` 和 huangkaoya 的提交 `898d891`。

| 问题 | 代码里的原因 | 处理 | 验证情况 |
|---|---|---|---|
| **视角不能缩放** | huangkaoya 上游版：滚轮缩放只在 `freeCamera=true` 时生效（`CameraZoom.ts`），而负责打开这个开关的 `MockDevToolsApi.registerVar` 只是个空壳，所以普通玩家根本缩放不了。ammaar 的版本已经改好：滚轮或触控板双指滑动缩放，范围从"整张地图刚好装满屏幕"到 2 倍（`CameraZoom.ts`、`WorldView.ts`）。另外，原文说的"zoom out 参数"如果指的是 `fullScreenZoomOut=1.3`，这个值在两个仓库里**都没有被任何代码读取**，改了也没用 | 用 ammaar 版本，**不需要额外改** | 读代码确认；没在真机上试手感。如果觉得触控板太灵敏，每次滚动的步长 `0.1` 在 `WorldInteraction.ts` 的 `handleWheel` 里 |
| **建造菜单太短** | 右侧建造栏能显示几行，是按画面高度算的：`Hud.ts` 里 `repeaterCount = floor((画面高 − 顶部 − 底部) / 每行高度)`。默认分辨率是 `config.ini` 里的 1024×768，桌面版分辨率列表最高只有 1920×1080 | 补丁在 `Resolution.tsx` 里加了 2560×1600、2560×1440、1920×1200；也可以直接全屏 | 类型检查和构建都通过；没在真机上看效果 |
| **没有中文** | ammaar 版本用的是从你自己 `langmd.mix` 里提取的**英文**尤里表（`generalmd.csf`）。huangkaoya 版本带中文表，但只覆盖红警2（4480 条，比如"遭遇战""美国大兵""巨炮"），**尤里新增的条目没有**（我抽查了 Name:SLAV、Name:BFRT、Name:YACNST 等，都缺）。这正好对应原文"能转译的转译，不能转译的自己翻译" | `tools/merge_csf_zh.py`：中文表里有的条目用中文；没有的保留英文，并写进 `yr_zh_glossary.tsv`。你在第三列填好中文后重跑 `install.sh`，填过的条目优先使用。输出文件的语言标记是简体中文，引擎会同时加载 `zh-CN.json` | 用合成数据测试，并用**引擎自己的 `CsfFile.ts`** 解析输出：识别为 `zh-CN`，中英混合和换行都正确。你那份真实英文表里有多少条缺中文，要在你的机器上跑过才知道 |
| **字体** | 这个引擎不用原版的位图字体 `game.fnt`，文字用浏览器字体渲染（`'Fira Sans Condensed', Arial, sans-serif`）。中文字形会自动用系统字体补上（macOS 上通常是苹方），所以不会出现方块 | 不需要处理。原文换 FreeSans 是为了外观更像经典版，属于审美选择 | 读代码确认；没截图验证 |
| **调到最快还是慢** | 见下一节 | 补丁 | 模拟验证（见下一节） |

### 速度问题的根因

- **满速是多少**：游戏速度滑块 0–6 档，第 6 档（最快）= 每秒 60 个逻辑帧（tick），由 `GameSpeed.ts` 写死。每个 tick 让游戏内时钟前进 1/15 秒，所以满速时游戏时钟走得是现实的 4 倍。
- **为什么会达不到**：`GameScreen.ts` 给游戏循环设了 `skipBudgetMillis: 8`，也就是每渲染一帧，最多花 8ms 跑游戏逻辑。在 `GameAnimationLoop.ts` 里，超出预算后剩下的 tick 会被**直接丢掉，不会补**。结果是：只要单个 tick 超过约 8ms，并且"逻辑 + 渲染"超过一帧的时间（60Hz 下是 16.7ms），每帧就只能跑 1 个 tick，**游戏速度会被压到和帧率一样**，30fps 时就只有一半速度。分辨率开大，渲染变重，会更容易触发。原文说的"某个渲染逻辑把速度上限卡死"，我推测就是这里，但无法确认他改的就是这一处。
- **补丁做了什么**：
  1. 预算从 8ms 改成 33ms（约两帧的时间），`GameScreen.ts` 和 `ReplayScreen.ts` 都改了；
  2. 新增可选的 `?turbo=` 网址参数，把最快档乘上 1–4 倍（`GameSpeed.ts`）。它只改变游戏推进的快慢，不改变游戏逻辑本身。

模拟结果：`tools/sim/run.sh` 用一个虚拟时钟驱动引擎**原样的** `GameAnimationLoop.ts`（只把两个 import 换成空实现），目标是 60 tick/s：

| 显示器 | 单 tick 耗时 | 渲染耗时 | 原版 8ms 预算 | 补丁 33ms 预算 |
|---|---|---|---|---|
| 60Hz | 2ms | 4ms | 100% | 100% |
| 60Hz | 3ms | 20ms | 100% | 100% |
| 60Hz | 10ms | 8ms | **50%** | **100%** |
| 60Hz | 12ms | 10ms | **50%** | **100%** |
| 60Hz | 14ms | 12ms | 50% | 75% |
| 120Hz | 12ms | 10ms | 67% | **100%** |
| 60Hz | 20ms | 10ms | 50% | 50%（机器确实跟不上） |

完全去掉预算也不行：我测了单 tick 40ms 的情况，会掉进"越慢越追、越追越慢"的循环，帧率只剩 0.1fps。所以保留了预算，只是把它调大。我也试过把丢掉的 tick 记下来下一帧补跑，在模拟里没有任何改善，所以没有采用。

**在你机器上自测速度**：开一局，选最快档，用秒表计时 30 秒，看右侧栏的游戏时钟有没有走 **2:00**。如果明显不到，说明还有我没找到的瓶颈。

---

## 6. 没验证的地方（请当作风险）

- **没有在 Mac 真机上跑过。** 这个环境是 Linux，也没有游戏素材。我实际验证过的：补丁能干净地打上、TypeScript 类型检查没有新增错误（原工程本来就有 42 个，和改之前完全一样）、Vite 生产构建成功、`turbo` 参数解析的单元测试、汉化合并（用合成数据，并经引擎解析器读取）、速度模拟，以及 `install.sh` 的克隆、锁定提交、打补丁和重复执行（用一个假的游戏目录，到导入素材那一步就停了）。
- 原文作者的具体做法是我推测的（没找到原文）。
- M4 Max 的单核性能很强，正常对局里单 tick 可能远低于 8ms，那样原版其实也能满速。补丁主要保证大地图、后期、高分辨率时不掉速。
- 授权：Chrono Divide 引擎的作者没有开源；huangkaoya 仓库标的 GPL-3.0，ammaar 自己在 README 里也说这个授权链条"没法核实"。**仅限个人、非商业使用**，不要分发打包好的版本。
- 尤里条目的中文需要你自己（或交给我）翻译。不同版本的官方译名不一样（大陆版和台湾版就不同），我不替你选。

## 7. 来源和版本锁定（可追溯）

| 内容 | 来源 | 锁定版本 |
|---|---|---|
| 移植工程 | https://github.com/ammaarreshi/RedAlert2-Mac-iOS-iPad | `991945d60a7139d3c4c438326abb6d3c093b2497`（2026-08-08） |
| 中文 RA2 字符串表 | https://github.com/huangkaoya/redalert2 `public/general.csf` | `898d89188542a3028a232031ce1a0bdc7c605b6f`（2026-09-03） |
| 本目录的补丁 | `patches/ammaar-991945d-mac-fixes.patch` | 改了 4 个文件，+28 / −3 行 |
| SteamCMD 跨平台下载 | https://developer.valvesoftware.com/wiki/SteamCMD | — |
| 游戏 | Steam App 2229850 | — |

升级移植工程时，先把 `install.sh` 里的 `PORT_PIN` 改成新的提交，再看补丁能不能打上；打不上就要重新做补丁，不要硬打。
