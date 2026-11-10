# 变更记录

本仓库是 `coracoo/DockPorts` v0.2.1（commit `8f7ff5f`，2025-07-16，上游已停更）的内部 fork。
用户构建只打 `latest`，不强制 SemVer；此处按时间倒序记录每次变更，便于追溯。

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
