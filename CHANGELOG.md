# 变更记录

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

本项目 fork 自 `coracoo/DockPorts` v0.2.1（commit `8f7ff5f`，上游已停更，MIT）。
本 fork 维护者：lucifer-799。以下按时间倒序记录变更。

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
