# 变更记录

本仓库是 `coracoo/DockPorts` v0.2.1（commit `8f7ff5f`，2025-07-16，上游已停更）的内部 fork。
用户构建只打 `latest`，不强制 SemVer；此处按时间倒序记录每次变更，便于追溯。

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
