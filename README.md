# DockPorts（改进版）

> **来源声明（请务必阅读）**
>
> 本项目 fork 自 **DockPorts**（原作者 **coracoo**，上游 <https://github.com/coracoo/DockPorts>，
> 许可证 **MIT License**，见上游 README 的「许可证」一节）。
> 上游自 v0.2.1（commit `8f7ff5f`）后停更；本仓库在其基础上合入了若干上游 Issue 的修复
> 与若干可选增强，**本 fork 维护者：lucifer-799**（<https://github.com/lucifer-799/dockports>）。
> 本项目同样以 **MIT** 许可发布，完整条款见 [LICENSE](./LICENSE)（两方版权并存，须随分发保留）。
> 修改记录见 [CHANGELOG.md](./CHANGELOG.md)。

一个现代化的 Docker 容器端口监控和可视化工具，帮助您轻松管理和监控 NAS 或服务器上的端口使用情况。

- 🐳 **Docker 集成**：通过 Docker API 实时监控容器端口映射
- 🖥️ **系统端口监控**：使用 netstat 监控主机端口占用
- 📊 **可视化界面**：卡片式展示，支持桌面与移动端
- 🔄 **实时刷新**：手动 / 自动刷新
- 👁️ **端口隐藏**：可隐藏不需要显示的端口，并提供「已隐藏」标签页
- 🏷️ **来源标识**：区分 Docker 容器端口与系统服务端口
- 🔒 **可选访问密码**：设置 `DOCKPORTS_AUTH_PASSWORD` 即启用登录鉴权（不设置则与上游行为一致）

## 与上游的差异

在保持上游使用方式与配置格式不变的前提下，本 fork 合入以下改动（均为可选或纯修复）：

- 修复「一个容器多端口时服务名称只对一个生效」（上游 Issue #2）
- 端口号可点击跳转到对应服务（#4 / #5 / #6）
- 连续端口显示为明确区间，消除 `3000:2` 这类歧义（#5）
- 可选访问密码鉴权、退出登录入口（#7）
- 登录失败限流（含记录 TTL 与容量上限，避免无界增长）
- 非 ASCII 密码边界场景加固
- `.dockerignore` 排除 `.git/`，避免构建上下文把带凭据的 remote URL 带入镜像
- Dockerfile 基础镜像可参数化（`--build-arg BASE_IMAGE=...`）

详见 [CHANGELOG.md](./CHANGELOG.md)。

## 部署

### 方式 A：docker run（无需本地构建）

```bash
docker run -d --name dockports \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v "$PWD/config:/app/config" \
  -e DOCKPORTS_PORT=7577 \
  --restart unless-stopped \
  ghcr.io/lucifer-799/dockports:latest
```

打开 `http://<主机IP>:7577`。

### 方式 B：docker compose

```bash
curl -fsSLO https://raw.githubusercontent.com/lucifer-799/dockports/main/compose.yaml
docker compose up -d
```

`compose.yaml` 直接使用 `ghcr.io/lucifer-799/dockports:latest`，无需改任何变量。
需要可复现的固定版本时，把镜像改成具体版本即可（如 `:1.0.0`）。

> ⚠️ 本工具需要读取宿主 Docker 信息，因此使用 `network_mode: host` 并只读挂载 `/var/run/docker.sock`。

## 使用说明

1. 首次访问直接进入端口面板；若设置了 `DOCKPORTS_AUTH_PASSWORD`，则需要登录。
2. 面板会自动列出所有容器端口映射与主机端口占用；点击端口号可跳转到对应服务。
3. 可用「隐藏」功能屏蔽不需要关注的端口，在「已隐藏」标签页恢复。
4. 配置格式与上游一致，参见仓库内 `config.json.example`。

## 开发

```bash
pip install -r requirements.txt
python app.py                 # 本地运行（需可访问 Docker socket）
docker build -t dockports:local .
```

## 许可证

[MIT License](./LICENSE)

- 原作 **DockPorts** © 2026 **coracoo**（MIT）
- 本 fork 的修改 © 2026 **lucifer-799**

再分发请保留 `LICENSE`（两方版权）与来源声明。