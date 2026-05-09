# Hermes Offline（离线版）

这是 **Hermes 的离线版本**，用于在无外网或受限网络环境下使用与部署。

## 使用说明

1. 克隆本仓库到本地环境。
2. 按项目依赖完成本地安装与配置。
3. 在离线环境中启动并运行 Hermes。

> 说明：本仓库重点面向离线使用场景。

## Docker 一键启动（前后端同启）

### 构建镜像

```bash
docker build -t hermes-offline:latest .
```

### 运行镜像

```bash
docker run --rm -it -p 5000:5000 -p 18789:18789 hermes-offline:latest
```

默认后端端口 `5000`，前端端口 `18789`。
如果项目实际启动命令不同，可在运行时覆盖：

```bash
docker run --rm -it \
  -p 5000:5000 -p 18789:18789 \
  -e BACKEND_CMD='你的后端启动命令' \
  -e FRONTEND_CMD='你的前端启动命令' \
  hermes-offline:latest
```

### 方便调试（代码改完马上见效）

```bash
docker compose -f docker-compose.dev.yml up --build
```

`docker-compose.dev.yml` 已挂载本地代码目录到容器内（`./hermes-agent`、`./hermes-webui`），适合开发调试。
前提是前后端各自启动命令支持热更新（如 `flask --debug`、`vite dev`、`next dev` 等）。
