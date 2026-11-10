# 基础镜像可参数化：默认仍为上游 python:3.11-slim，
# 构建时可由流水线传 --build-arg BASE_IMAGE=10.10.10.204:10062/python:3.11-slim 走本地 Nexus
ARG BASE_IMAGE=python:3.11-slim
FROM ${BASE_IMAGE}

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 安装系统依赖、构建工具和Docker客户端
# apt 走清华 Debian 镜像（Debian 12 的 sources 为 deb822 格式 debian.sources）
RUN sed -i 's|deb.debian.org/debian|mirrors.tuna.tsinghua.edu.cn/debian|g; s|deb.debian.org/debian-security|mirrors.tuna.tsinghua.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
   sed -i 's|deb.debian.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list 2>/dev/null || true
RUN apt-get update && apt-get install -y \
    net-tools \
    procps \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    gcc \
    python3-dev \
    build-essential \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖，然后清理构建工具以减少镜像大小
RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt \
    && apt-get remove -y gcc python3-dev build-essential \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 复制应用代码
COPY . .

# 设置默认端口环境变量
ENV DOCKPORTS_PORT=7577

# 暴露端口（默认7577，可通过环境变量或命令行参数修改）
EXPOSE $DOCKPORTS_PORT

# 健康检查（使用环境变量；/healthz 免鉴权，启用访问密码后仍可用）
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${DOCKPORTS_PORT}/healthz || exit 1

# 启动应用（使用ENTRYPOINT支持命令行参数）
ENTRYPOINT ["python", "app.py"]
CMD []