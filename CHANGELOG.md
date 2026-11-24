# 变更记录

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

本项目 fork 自 `coracoo/DockPorts` v0.2.1（commit `8f7ff5f`，上游已停更，MIT）。
本 fork 维护者：lucifer-799。以下按时间倒序记录变更。

## [1.0.12] - 2026-11-24

### Fixed（ocr 全量审查 5 个 high）
- `templates/index.html:2119` 端口范围起始 0 被 truthiness 丢弃：改为 `!= null` 显式判断（loadPorts/performSearch 两处），端口 0 现为合法起始值。
- `templates/index.html:2006` 隐藏标签虚拟卡片绕过协议/范围过滤、一律标 TCP：新增与常规卡片一致的 `inScope` 判定（锁定范围 + 当前协议），不再泄漏视图外端口。
- `templates/index.html:2210` **`formatPortRange` 原始 API 值直插 innerHTML（XSS 残留）**：先用 `toInt` 校验为 0-65535 整数（非法返回空串），再经 `esc()` 转义后拼接；同文件全量排查 innerHTML 模板插值，编辑/批量编辑弹窗的端口值也补 `esc()`。参照 1.0.2 对 `displayName`/`fullName` 的修复方式。
- `app.py:1031` 端口边界 clamp 顺序错误（先 clamp 后 swap 会重新产生越界边界）：改为先交换顺序、再对两端分别 clamp。
- `app.py:593` host-network 容器缓存共享可变状态无锁：新增 `PortMonitor.cache_lock = threading.RLock()`，原方法重命名为 `_..._unlocked`，新增带锁包装方法返回缓存副本 `dict(result)`，避免并发请求读到半填充缓存或迭代中字典尺寸变化。

### Fixed（顺手 medium）
- 登录退避 `2 ** n` 指数封顶（≤10），避免长期重试触发超大整数幂运算。
- 5 处 `isinstance(port, int)` 改为 `type(port) is not int`，拒绝 bool（`true` 曾被存成端口 1）。

### Notes
- 本轮纯安全修复，不含功能变更；改动仅 `app.py` / `templates/index.html` / `templates/login.html` / 版本号。

## [1.0.11] - 2026-11-23

### Fixed
- **工具小方框内两行的间距与高度协调**（`templates/index.html`、`templates/login.html`）：
  1.0.10 实机确认 GitHub 图标与版本号已对齐，但用户指出两个问题，本版一并修复：
  1. **行间距**：`.sidebar-group--icons`（login 为 `.login-tools`）是纵向 flex，原 `gap: 0.45rem`（约 7px）
     使 `version-container` 行与 `theme-row` 行贴在一起；改为 **`gap: 0.75rem`（12px）**，
     两行之间留出呼吸空间（小框内边距也由 `0.5rem 0.45rem` 微调到 `0.6rem 0.5rem`）。
  2. **按钮高度对齐**：三个主题按钮框原为 **30px**，比上方 version 行（15px 内容）高一倍，视觉突兀；
     收至 **24px**（内部 SVG 仍 15px、`inline-flex + align-items:center` 居中，点击区域仍够用），
     与版本号那一行般配。三个按钮统一 `width/height:24px`、`line-height` 由 flex 居中保证一致。
  3. 两行保持 `align-items:center`、小框 `flex-direction:column` 水平居中，不会出现一行居中一行靠左。

其它保持不变：图标与版本号 1em/15px 对齐、两个独立链接（仓库 / releases）、去下划线、
三主题按钮 + auto 跟随、侧栏 `gap:1rem`、app.py 安全代码（`git diff app.py` 为空）。

## [1.0.10] - 2026-11-23

### Fixed
- **图标与版本号高度对齐（根因修复）**：此前 1.0.9 已将图标缩到 16px、版本号 15px、`align-items:center`，
  但用户肉眼仍明显不齐。逐项排查后确认根因有三：
  1. **单位错配**：图标固定 16px 与文字 15px 永远差 1px，且不同字体下字高随字体变化，固定 px 无法自适应；
  2. **行盒基线间隙**：`<img>` 虽已是 `display:block`，但其外层 `.github-icon` 原为 `inline-flex; line-height:1`，
     仍引入行盒高度，使图标在容器内相对文字下沉/上浮；
  3. **em 基准缺失**：`login.html` 的 `.icon` 用 `1em` 时，父 `.version-container` 并未设定 `font-size`，
     1em 实际取 body 的 16px——与 index 页不同，两个页面图标大小不一致。
  修法：`version-container` 显式 `font-size:15px; line-height:1`；GitHub 图标改
  `width:1em; height:1em; display:block`（computed = 15px，与字号天然一致）；
  `.github-icon` 容器改 `display:block; line-height:0`（彻底消除行盒基线留白）；
  `<img>` 的 width/height 属性同步设为 15（无 CSS 时也一致）；
  三个主题按钮 SVG 由 18px 统一到 **15px**（与图标同尺寸，避免大小混搭）。
  两模板（index.html / login.html）同样处理，两个页面表现一致。

### Known
- 本环境无浏览器内核（playwright 已装但 chromium 未安装），**无法做可视化截图验证**；
  对齐依据为上述 CSS 选择器命中、优先级（仅一条规则设置图标尺寸，无覆盖）、computed 尺寸推算（1em=15px）。

其它保持不变：两个独立链接、去下划线、侧栏 gap:1rem、三主题按钮 + auto 跟随、
左侧布局、app.py 安全代码（`git diff app.py` 为空）。

## [1.0.9] - 2026-11-23

### Fixed
- **GitHub 图标与版本号视觉大小协调**（`templates/index.html`、`templates/login.html`）：
  1.0.8 把版本号从 0.78rem 放大到 15px 后，GitHub 图标仍为 24px，图标明显大于文字、失衡。
  本版将 GitHub 图标**从 24px 缩小到 16px**（`<img>` 的 `width`/`height` 属性与 CSS
  `.version-container .icon` 同步修改），并把版本号 `line-height` 由 24px 调到 18px，
  与 16px 图标 + 15px 字高协调；`version-container` 保持 `inline-flex; align-items:center`
  垂直居中。
- 三个主题按钮的 SVG 已是 18px，与这一行协调，未改动。

其它保持不变：图标→仓库、版本号→releases 两个独立链接、去下划线、侧栏模块间距
`gap:1rem`、三主题按钮 + auto 跟随、左侧布局位置、app.py 安全代码（`git diff app.py` 为空）。

## [1.0.8] - 2026-11-23

### Fixed
- **GitHub 图标与版本号对齐 / 放大 / 去下划线**（`templates/index.html`、`templates/login.html`）：
  - `version-container` 用 `display:inline-flex; align-items:center`，图标（24×24）与版本号垂直居中对齐；
  - 版本号字号由 `0.78rem` 提升到 **15px / font-weight 600 / line-height 24px**，视觉更清晰；
  - 版本号与图标的全状态（`hover` / `focus` / `visited` / `active`）**强制 `text-decoration:none !important`**，
    移除此前的 hover 下划线；反馈改为文字颜色提亮（`--dp-text-strong`）。

### Changed
- **两个独立链接，点击目标分离**（此前整行一个链接）：
  - 点 **GitHub 图标** → `https://github.com/lucifer-799/dockports`（仓库主页）
  - 点 **版本号 `v1.0.8`** → `https://github.com/lucifer-799/dockports/releases`（Release 页）
  - 各自独立 `<a target="_blank" rel="noopener">`，可点区域清晰。
- **明暗主题由单按钮循环改为三个独立按钮**（`data-mode=auto|light|dark`，一排紧凑展示）：
  - 自动 = 半圆 / 明亮 = 太阳 / 暗夜 = 月亮，各带 `title` / `aria-label`；
  - 当前模式按钮**高亮激活态**（`.theme-btn.active`，用 `--dp-accent` / `--dp-surface`）；
  - `localStorage['dockports-theme']` 持久化；点击各自 `set(mode)`；
  - **auto 模式后台跟随浏览器**：`matchMedia('(prefers-color-scheme: dark)')` 监听 `change`，
    仅当 `current === 'auto'` 时实时应用系统主题（原逻辑保留并改为按激活态判断）。
  - 登录页 `login.html` 同样具备三按钮 + 两独立链接（右下角工具区）。
- **侧栏模块间距**：此前「端口分类检索」大方框、「端口范围锁定」、「GitHub/主题小方框」三块
  互相紧贴（`port-range-lock` 靠 `margin-top: 2rem`、其它靠 `margin-bottom: 0.8rem`，间距不一致）。
  改为侧栏统一 `display:flex; flex-direction:column; gap:1rem`（16px），移除各模块自带 margin，
  三块之间间距一致、透气；`port-range-lock` 的浅色与边框也收敛到 `--dp-surface` / `--dp-card-border`
  变量（跟随明暗主题）。窄屏下侧栏 `width:100%`，flex 列布局不溢出。
- 未改变功能逻辑与安全代码：`git diff app.py` 为空（`esc()` / `CONFIG_IO_LOCK` 原样）；
  主题 CSS 变量与其余功能保持不变。

## [1.0.7] - 2026-11-23

### Changed
- **前端图标/分组布局调整**（`templates/index.html`）：
  - 「📊 端口分类检索」标题与其下的分类图标列表（全部 / 宿主机 / 容器 / 未使用 / 已隐藏）
    用一个**方形边框容器**（`.sidebar-group--catalog`）整体框起，视觉上成为一组。
  - 工具区——**GitHub 图标 + 版本号** 与 **明暗主题切换按钮**——从右下角浮动（`position: fixed`）
    **移入左侧边栏「端口范围锁定」按钮下方**，放入一个**小方形边框容器**（`.sidebar-group--icons`），
    内部纵向两行：
    - 第一行 `version-container`：GitHub 图标（自绘 `static/github-light.svg`，24×24；
      暗色主题下用 `filter: invert(1)` 反色保证可见）+ 版本号文本 `v1.0.7`，整行即 GitHub 仓库链接；
    - 第二行 `theme-row`：明暗主题切换按钮（太阳 / 月亮 / 半圆），单独一行。
  - 方框样式统一使用主题变量 `--dp-card-border` / `--dp-surface`，明暗主题下自动适配。
  - 仅调整 DOM 位置与 CSS，**未改动任何功能逻辑**：主题切换、GitHub 链接、端口范围锁定、
    `esc()` 转义与后端 `CONFIG_IO_LOCK` 等安全代码全部原样。

### 说明
- 登录页 `login.html` 没有「端口范围锁定 / 分类检索」区域，故其主题按钮与 GitHub 图标
  **仍保持在右下角**（页脚位置不变），功能与样式不受影响。

## [1.0.6] - 2026-11-23

### Security
- **移除按钮双重绑定**（`templates/index.html`）：`#lockRangeBtn`、`#resetRangeBtn` 同时存在
  inline `onclick` 与 `addEventListener('click')`，一次点击触发两次——端口范围锁定会「锁上后
  立即解锁」，锁定功能实际不可用。已删除两处 inline `onclick`，统一由 `addEventListener` 接管，
  点击只触发一次、范围锁定正常生效。
- **补齐并发写锁**：`app.py` 的四个隐藏端口写接口（`/api/hide_port`、`/api/unhide_port`、
  `/api/hide_ports_batch`、`/api/unhide_ports_batch`）此前 `load_hidden_ports() → 修改 →
  save_hidden_ports()` 整段在 `CONFIG_IO_LOCK` 之外（1.0.3 只修了配置保存那处，这一处漏了）。
  现已整段纳入 `with CONFIG_IO_LOCK:`（`RLock` 可重入，与内部原子写共用同一把锁不冲突）。

### Fixed
- 端口号在**文本节点**中的插值补 `esc()`（`${card.port}` → `${esc(card.port)}`，共 4 处；
  属性侧已在 1.0.4 修复）。
- 协议过滤白名单与 `data-protocol` 标记值大小写不一致（标记值为小写 `tcp`/`udp`，
  判断用大写 `TCP`/`UDP`），导致点击 TCP/UDP 时按钮高亮不更新——已统一为小写比较。
- `filterPorts()` 增加协议过滤：`refreshPorts()` 与 `switchProtocol()` 共用该函数，
  此前刷新后不按当前协议过滤，会显示全部协议且与顶部按钮状态不一致。
- 后端 `unknown_range` 的隐藏判定与前端对齐：由「范围内任一端口被隐藏即整体隐藏」
  改为「范围全部端口被隐藏才隐藏」（前端已在 1.0.4 修正，后端此前未同步）。

### Known issues（复核后确认无需改动）
- `app.py` 的端口空隙（gap）生成已包含尾部区间（末尾 gap 卡片会扩展到范围上限，
  否则生成 `final_gap`），复核后未发现遗漏。

### Known issues（仍未处理）
- `Dockerfile` 的 `HEALTHCHECK` 只读运行时 `DOCKPORTS_PORT`，通过命令行 `--port` 覆盖时探不到。
- 深色主题采用「变量 + 覆盖」落地，个别历史硬编码颜色在暗夜下可能仍有轻微不协调。

## [1.0.5] - 2026-11-23

### Added
- **明暗主题切换**（`templates/index.html`、`templates/login.html`）：
  - 三种模式：**明亮 / 暗夜 / 跟随系统**，单个按钮循环切换（light → dark → auto → light）；
    按钮图标随模式切换（太阳 / 月亮 / 半圆），并带 `title` 与 `aria-label` 说明当前模式。
  - **状态持久化**：`localStorage` 键 `dockports-theme`，默认 `auto`；隐私模式下读写失败会静默回退。
  - **跟随系统实时生效**：`auto` 模式下监听 `matchMedia('(prefers-color-scheme: dark)')` 的 `change`
    事件，系统切换深浅色时页面即时跟随。
  - **实现方式**：CSS 自定义属性（`--dp-bg` / `--dp-text` / `--dp-card-bg` / `--dp-border` /
    `--dp-input-bg` / `--dp-shadow` / `--dp-accent` 等）定义明亮与暗夜两套取值，通过
    `body[data-theme="light|dark"]` 切换；`auto` 用 `@media (prefers-color-scheme: dark)` 映射到暗夜取值。
    仅新增变量定义与覆盖规则，**不改变原有布局**。
  - **按钮位置**：右下角固定容器 `.dp-footer-dock` 内，与 GitHub 图标**并排**（间距 8px），
    两个页面都生效（登录页切换主题后登录进去仍保持）。
- 说明：本版仅前端样式与交互，**未改动 `app.py`**（1.0.4 的 `esc` / `RLock` 等安全修复原样保留）。

### Known issues（沿用上一版，未处理）
- 卡片按钮 inline `onclick` 与 `addEventListener` 双触发（需统一改事件委托）。
- `Dockerfile` 的 `HEALTHCHECK` 只读运行时 `DOCKPORTS_PORT`，`--port` 覆盖时探不到。
- `app.py` 端口空隙（gap）生成在尾部区间的边界处理。
- 深色主题采用「变量 + 覆盖」方式落地，个别历史硬编码颜色（如部分 badge 背景）
  在暗夜下可能仍有轻微不协调，后续可逐步收敛到变量。

## [1.0.4] - 2026-11-23

### Security
- **修复 HTML 属性注入面**（`templates/index.html`）：`card.port` / `container_port` / `start_port` /
  `end_port` / `port_count` / `available_count` / `source` 此前直接拼进 `href` / `title` / `class` /
  `onclick` 属性值。本版做**类型校验 + 转义双重防护**：
  - 新增 `toInt(v, min, max)`（`Number.isInteger` + 范围校验）与 `portAttr(v)`（端口 1–65535，
    非法返回空串、不参与拼接）
  - `portLinkAttrs`：`card.port` 先经 `toInt` 校验（非法则整段属性不生成），`href`/`title` 值再经 `esc()`
  - `container_port` → `esc()`；`class` 中的 `card.source` → `esc()`
  - `port_count` / `available_count` → `toInt(x, 0) ?? 0`（非整数一律显示 0）
  - `onclick` 里的 `start_port`/`end_port`/`port` → 走 `portAttr()` 校验
  - `querySelector` 的 `data-filter` / `data-view` / `data-protocol` 拼接前加枚举白名单校验
- `.dockerignore` 的凭据类规则统一加 `**/` 前缀：`**/.env`、`**/.env.*`、`**/*.pem`、
  `**/*.key`、`**/*.token`、`**/*.log`、`**/*.py[cod]` —— 子目录中的凭据文件才真正被排除。
- GitHub Actions 的第三方 action 由可变 major tag **pin 到具体版本**：
  `actions/checkout@v4.2.2`、`docker/setup-buildx-action@v3.10.0`、`docker/login-action@v3.3.0`、
  `docker/metadata-action@v5.7.0`、`docker/build-push-action@v6.16.0`（降低供应链风险）。

### Fixed
- `isPortHidden()` 对 `unknown_range` 的判定与 `gap` 分支统一：此前「范围内任一端口被隐藏」
  即整体判为已隐藏，导致部分隐藏的端口范围在列表中整体消失；改为「范围内全部端口都被隐藏」
  才视为隐藏。

### Known issues（本版未处理，不影响发布）
- `index.html` 卡片的按钮同时存在 inline `onclick` 与 JS `addEventListener`，个别场景会触发两次
  （需统一改为事件委托，涉及多处交互逻辑，留待后续）。
- `Dockerfile` 的 `HEALTHCHECK` 只读取运行时 `DOCKPORTS_PORT`，通过命令行 `--port` 覆盖监听端口时
  健康检查探不到（需前后端协同改造）。
- `app.py` 端口空隙（gap）生成在尾部区间的边界处理。

## [1.0.3] - 2026-11-23

### Security
- 修复列表视图「未知服务」卡片的协议徽章：`${card.protocol.toUpperCase()}` 此前直接拼进 `innerHTML`（未转义），
  改为与同文件其它 4 处一致走 `renderProtocolBadges()`（内部已 `esc()`）。
- `.dockerignore` 的 `*.token` / `*.key` 缺少 `**/` 前缀，无法匹配子目录文件；改为 `**/*.token` / `**/*.key`，
  使「排除凭据文件」的本意真正生效。

### Fixed
- 端口批量命名接口的「读-改-写」整段纳入 `CONFIG_IO_LOCK`（此前只锁单次写入，并发
  `load_config() → 修改 → save_config()` 仍会互相覆盖导致丢更新）；同时把该锁改为可重入 `RLock`，
  避免与内部 `atomic_write_json()` 的同一把锁自死锁。
- GitHub Actions 的 `latest` 标签在 tag 推送时不再缺失：`type=raw,value=latest` 的 `enable`
  由 `{{is_default_branch}}`（对 tag ref 恒为 false）改为
  `${{ github.ref_type == 'tag' || github.ref == 'refs/heads/main' }}`，main 与 `v*` 都产出 `latest`。

### Known issues（未在本版处理）
- `Dockerfile` 的 `HEALTHCHECK` 读取运行时 `DOCKPORTS_PORT`，但若通过命令行 `--port` 覆盖监听端口，
  健康检查仍探环境变量端口 —— 需前端/后端协同改造，留待后续版本。
- `app.py` 端口空隙（gap）生成在尾部区间的边界处理、以及 `index.html` 的三处小逻辑
  （按钮 inline 事件冲突、`isPortHidden` 对 `unknown_range` 的判定、虚拟卡片生成）仍为已知缺陷，不影响发布。

## [1.0.2] - 2026-11-23

### Security
- **修复 Stored XSS**：`templates/index.html` 中 API 返回的容器名/label 派生字段（`displayName`、`fullName`）与端口协议字符串此前直接拼进 `innerHTML`。新增 `esc()` HTML 转义函数，卡片视图、列表视图与协议徽章渲染处的所有不可信插值均改为 `esc(...)`。
- **修复脚本注入面**：GitHub Actions 的 Summary 步骤不再把 `${{ steps.meta.outputs.tags }}` 直接拼进 `run:`，改为经 `env:` 传入后用 `"$TAGS"` 引用。
- **GHCR 镜像名强制小写**：新增一步用 shell `${GITHUB_REPOSITORY,,}` 计算小写镜像名，避免仓库名含大写（如 `DockPorts`）时 push 失败。
- **容器以非 root 运行**：Dockerfile 新增 `useradd app`（uid 1000）、`COPY --chown=app:app`、`USER app`；`compose.yaml` 补充 `group_add` 说明（读取 docker.sock 需与宿主 socket 属主组同组）。
- **并发持久化安全**：配置/隐藏端口写入改为 `atomic_write_json()`（临时文件 + `fsync` + `os.replace`，外加进程内 `CONFIG_IO_LOCK`），消除多请求 load→改→save 竞态与截断写。

### Fixed
- `refreshPorts` 刷新后不同步更新全局 `portsData`（此前只渲染响应，后续筛选/隐藏基于旧数据）→ 改为先更新 `portsData` 再 `displayPorts(filterPorts(...))`。
- Docker 端口映射的**协议被丢弃**（一律当 TCP）→ `get_docker_ports` 保留 `protocol`（从 `80/tcp`、`53/udp` 解析），端口按实际协议归入 TCP/UDP 视图与过滤。
- 移除上游作者的 `docker-publish.yml`（发布到其阿里云个人镜像仓库，且 `type=raw,latest` 对 tag ref 不生效导致 tag 不构建）；发布统一由 `build.yml` 承担，main 与 `v*` tag 均构建。

### Changed
- `.dockerignore` 排除运行时 `config/config.json` 与 `config/hidden_ports.json`，避免把本地配置打进镜像。
- 依赖升级（仅升受 CVE 影响的包，不跳大版本）：Werkzeug `2.3.7 → 3.0.3`（CVE-2024-34069）、urllib3 `2.0.7 → 2.2.2`（CVE-2024-37891）、requests `2.31.0 → 2.32.3`（CVE-2024-35195）、Jinja2 `3.1.2 → 3.1.4`（CVE-2024-22195）、certifi `2023.7.22 → 2024.8.30`（过期 CA）。

## [1.0.1] - 2026-11-23

### Added
- 网页 favicon：新增 `static/favicon.svg`（自绘几何图标，集装箱 + 端口造型，未使用任何官方 logo）
  与 `static/favicon.ico`（16/32/48/64 多尺寸），并在 `index.html` / `login.html` 的 `<head>` 中引用。
- 页脚 GitHub 图标链接：`index.html` 右下角固定位置、`login.html` 页脚各加一个 inline SVG
  octocat mark（18px、`fill=currentColor`、hover 提亮），指向
  <https://github.com/lucifer-799/dockports>（新窗口打开，含 title/aria-label）。

## [1.0.0] - 2026-11-23

### Added
- 可选访问密码鉴权（`DOCKPORTS_AUTH_PASSWORD`，未设置时行为与上游一致）、退出登录入口
- 登录失败限流（含记录 TTL 淘汰与容量上限，避免无界增长）
- 端口号可点击跳转到对应服务
- 容器化发布：`compose.yaml`（公网镜像 `ghcr.io/lucifer-799/dockports`）、
  `.github/workflows/build.yml`（Actions 自动构建推 ghcr）

### Fixed
- 一个容器多端口时服务名称只对一个生效
- 连续端口显示改为明确区间，消除 `3000:2` 类歧义
- 非 ASCII 密码边界场景加固
- `.dockerignore` 排除 `.git/`，避免构建上下文把带凭据的 remote URL 带入镜像

### Changed
- Dockerfile 基础镜像可参数化；apt/pip 使用国内镜像源加速
- 补充来源声明与 LICENSE（MIT，两方版权：coracoo 原作 + lucifer-799 fork）

## 2026-11-10 修复 D1/D2/D3（测试第一轮静态复核）

> 口径说明：测试专家第一轮静态复核基于 `7a2a92c`；实际仓库已先行推到 `e82f672`
> （ocr 自审 2 个 commit），故本段按真实代码状态处理，不重复覆盖既有修复。

| 编号 | 级别 | 结论与处置 |
|---|---|---|
| **D1** | 高 | `hmac.compare_digest(str, str)` 非 ASCII 密码抛 `TypeError` → 正确密码永远登不进、攻击者提交非 ASCII 得 500。**已在 `27f0da0` 修为两侧 `.encode('utf-8')` 后按 bytes 比较**（即 ocr 自审 low/bug #5 同一问题）。本次再补空值/None 边界：`request.form.get('password') or ''` + 非 str 强转，保证任何输入都不会在 `.encode()` 抛异常。「未设密码完全不启用」「`/healthz` 免鉴权」「开放重定向防护」均保持不变 |
| **D2** | 中 | 新增 `.dockerignore`：排除 `.git/`、`__pycache__/`、`*.py[cod]`、`.env*`、`*.token`/`*.key`/`*.pem`、`.opencodereview/`、OCR 结果 JSON、常见测试/编辑器临时产物。`Dockerfile` 是 `COPY . .`，此前会把 `.git/` 连同可能的凭据 URL 打进镜像（上游公开镜像正是这样泄露 `ghs_` token）。**显式保留** `templates/`、`config.json.example`、`requirements.txt`、`Dockerfile` |
| **D3** | 低 | `index.html` 全文 0 处 `logout`，README 却承诺 `/logout`。`index()` 渲染时传入 `auth_enabled`，模板在 header 右上角用 Jinja 条件渲染「🚪 退出登录」链接（指向 `/logout`）；**仅启用访问密码时可见**，鉴权关闭时不显示，样式沿用 header 白色半透明配色、含移动端适配 |

### ocr 自审意见处置（job 9ee94c）

两轮 ocr 共 6 条发现，已在本次之前的 2 个 commit **全部修复、无悬置项**：
- `27f0da0`：high/security 1（session 密钥改 `secrets.token_hex(32)` 随机值，不再由密码派生）、
  medium/bug 2（`ports:null` / `service_name` 非字符串 → 400 而非 500）、
  medium/security 1（`/login` 基于时间戳的指数退避限流）、
  low/bug 1（**即 D1**，`compare_digest` 改 UTF-8 bytes）。
- `e82f672`：增量复验 medium/security 1（限流字典加 `LOGIN_FAILURE_TTL=3600s` +
  `LOGIN_FAILURES_MAX_IPS=4096` 淘汰，杜绝无界增长）。

本次没有新的 `severity=high/critical` 待处理；对 D1 按本次要求补了 None/空值边界加固。
未引入任何新的 Python 依赖，`requirements.txt` 与 `Dockerfile` 的 pip 层未改。

---

## 2026-11-10 ocr 自审修复（开发改完 → 测试专家介入前的自检）

用 `ocr v1.13.7`（内网 new-api / `deepseek-v4-pro`）对 `8f7ff5f..HEAD` 的净改动做一次代码审查。
口径说明：`main == HEAD`，按补充要求给的 `--from main --to HEAD` 会得到空 diff，故据实改为
`--from 8f7ff5f --to HEAD`（上游基线 → 本次改动）。preview：4 个代码文件、`+359 -89`
（CHANGELOG/README 被规则按扩展名排除）；实际审查 4 文件、耗时 17m47s、0 次 LLM 失败，
结果 5 条发现（high 1 / medium 3 / low 1），全部在 `app.py`，**已全部修复**，未留悬置项。

| # | 级别/类别 | 发现 | 处理 |
|---|---|---|---|
| 1 | high / security | session 签名密钥由密码派生 → 持 cookie 者可离线爆破弱密码并伪造登录态 | 改为 `secrets.token_hex(32)` 随机密钥；`DOCKPORTS_SECRET_KEY` 可显式固定；未设置且启用鉴权时启动日志 warning 提示「重启/多副本需固定密钥」 |
| 2 | medium / bug | `ports: null` 且无 `port` 时 `data['port']` 抛 KeyError → 500 | 显式判缺，返回 400 `缺少 port 或 ports 字段` |
| 3 | medium / bug | `service_name` 非字符串时 `.strip()` 抛 AttributeError → 500 | 先 `isinstance(str)` 校验，返回 400 `服务名称必须是字符串` |
| 4 | medium / security | `/login` 无限流，可在线爆破密码 | 自实现**基于时间戳**的内存计数 + 指数退避（连续 5 次失败起、1→2→4…上限 30s，退避窗口内直接拒绝且不校验密码，`threading.Lock` 并发安全，成功登录清空）；**不引入 flask-limiter**，避免改 `requirements.txt` 与依赖面 |
| 5 | low / bug | `hmac.compare_digest` 传 str 时非 ASCII 密码抛 TypeError → 500 | 两侧统一 `.encode('utf-8')` 后按 bytes 比较 |

涉及文件：`app.py`（5 处）、`README.md`（密钥/限流说明同步）。
未改 `requirements.txt`、未新增依赖；鉴权仍默认关闭，向后兼容不变。

### 增量复验（低 effort，仅审修复引入的增量）

对 `7a2a92c..HEAD` 再跑一次 `--effort low`：1 个文件、5m26s、0 次 LLM 失败，
**1 条 medium/security**，指向本轮新增的限流代码：`LOGIN_FAILURES` 是无界字典，
不同 IP 失败记录永不淘汰 → 慢内存泄漏 / DoS。**已修复**：加 `LOGIN_FAILURE_TTL=3600s`
过期淘汰 + `LOGIN_FAILURES_MAX_IPS=4096` 容量上限（超限时按时间淘汰最旧的一批），
清理在 `LOGIN_FAILURES_LOCK` 内完成。修复后复验共 6 条发现，**全部处理、无悬置项**。

验证：本机隔离 venv（Flask 2.3.3 / Werkzeug 2.3.7，与 `requirements.txt` 一致）
用 Flask `test_client` 做了 16 项真实 HTTP/行为验证（含非 ASCII 密码登录、401/302、
400 输入校验、`ports` 数组 `MySvc-2` 命名、限流窗口生效与释放、TTL/容量淘汰），全过。
ubuntu 开发机无 flask/pip，未在开发机安装依赖，HTTP 验证在隔离环境完成、未污染任何环境。

---

## 2026-11-10 内部 fork 首次合并

基线：上游 `8f7ff5f`（v0.2.1）。上游无 CHANGELOG.md，本文件为新建。

### 自定义改动合并

- 合并原部署中宿主机挂载的自定义 `app.py`（58556 B，sha256
  `5462b54cae5ecf60a98be2f697cd2d11de8e65fe8771b382a6e7fa5c132527dd`，
  debian/ubuntu 两份哈希一致）。与官方 `app.py`（58521 B）的 `diff -u` 只有一行、净增 35 字节：

  ```diff
  -                    'service_name': config_service_name or host_info.get('service_name', '未知服务'),
  +                    'service_name': config_service_name or host_info.get('container_name') or host_info.get('service_name', '未知服务'),
  ```

  功能：宿主机/host 网络端口卡片的服务名，在配置文件未显式命名时，**优先显示监听该端口的容器名**，
  其次才是 `host_info['service_name']`，最后回退「未知服务」。使 host 网络容器（无法从 Docker
  端口映射表识别）在界面上显示真实容器名，而不是笼统的「未知服务」。

### 一并修复的上游 Issue

| Issue | 修复内容 | 涉及文件 |
|---|---|---|
| #7 / #5 | 新增访问密码登录鉴权：环境变量 `DOCKPORTS_AUTH_PASSWORD` 注入、`hmac.compare_digest` 校验、Flask session、`before_request` 保护全部页面与 `/api/*`、登录/登出页、`/healthz` 免鉴权；未配置密码时完全不启用（向后兼容）。密码不写入仓库任何文件 | `app.py`、`templates/login.html`(新)、`templates/index.html`、`Dockerfile`、`README.md` |
| #4 / #5 / #6 | 端口卡片/列表的端口号可点击跳转 `http(s)://当前主机名:<端口>/`，`target=_blank rel=noopener noreferrer`；前端 401 统一跳登录 | `templates/index.html` |
| #2 | 一个服务名对应多个端口时，后端自动分配 `名称 / 名称-2 / 名称-3` 独立条目；新增 `ports` 数组一次提交；前端批量命名改为单次请求，消除并发覆盖与竞态 | `app.py`、`templates/index.html` |
| #5 | 连续端口显示由易误解的 `3000:2`（冒号+数量）改为明确的区间 `3000-3001`；同步修正 gap 与 unknown_range 两种卡片 | `templates/index.html` |

### 本期不做（建议后续独立迭代）

| Issue | 理由 |
|---|---|
| #3 Docker Network 拓扑视图 | 需要新增网络/容器关系采集与全新可视化组件，属独立大功能；塞进本次会让改动失控，冒烟/功能回归兜不住 |
| #6 局域网多主机扫描 | 需要多主机探测、凭据与目标管理，是独立子系统；本期只做 #6 中「端口跳转链接」这一同类轻量需求 |

> 参考提示：Issue #7 评论中第三方 `orsoman/dockports` 实现了带密码的增强版，但反馈存在「端口占用异常」，
> 且其改动端口获取方式（netstat 差异）与本项目行为不一致，**未照抄**，仅按上游代码结构独立实现鉴权。

### 安全

- 未沿用上游公开镜像内 `.git/config` 携带的 GitHub App token 内嵌写法；本仓库所有凭据均不入库，
  clone remote 为纯 URL，构建期凭据只通过环境变量注入。
- 上游无 LICENSE，本 fork 仅用于 homelab 内部自用。
