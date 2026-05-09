# Hermes Offline（离线版）

这是 **Hermes 的离线版本**，用于在无外网或受限网络环境下使用与部署。

## 一键 Docker 打包与启动

> 约定目录：
> - 本仓库默认不强制目录名，请通过 `FRONTEND_DIR` / `BACKEND_DIR` 指定
> - 例如：前端在 `web`，后端在 `server`

### 1) 构建镜像（联网环境执行一次）

```bash
docker build -t hermes-offline:latest \
  --build-arg FRONTEND_DIR=<你的前端目录> \
  --build-arg BACKEND_DIR=<你的后端目录> .
```

### 2) 启动（可直接 `docker run`）

```bash
docker run -d --name hermes-offline \
  -p 18789:18789 \
  -p 5000:5000 \
  hermes-offline:latest
```

启动后：
- 前端：`http://localhost:18789`
- 后端：`http://localhost:5000`

### 3) 离线环境使用

在可联网机器先导出镜像：

```bash
docker save hermes-offline:latest -o hermes-offline.tar
```

把 `hermes-offline.tar` 拷贝到离线机器后导入并运行：

```bash
docker load -i hermes-offline.tar
docker run -d --name hermes-offline -p 18789:18789 -p 5000:5000 hermes-offline:latest
```

## 可选启动参数

- `BACKEND_START_CMD`：后端启动命令（默认 `python app.py`）
- `BACKEND_PORT`：后端端口（默认 `5000`）
- `FRONTEND_PORT`：前端端口（默认 `18789`）
- `FRONTEND_BUILD_DIR`：前端构建产物目录（默认优先 `/app/frontend/dist`，其次 `/app/frontend/build`）

示例：

```bash
docker run -d --name hermes-offline \
  -e BACKEND_START_CMD="gunicorn -b 0.0.0.0:5000 app:app" \
  -p 18789:18789 -p 5000:5000 \
  hermes-offline:latest
```


## 开发调试（推荐，不用每次重打镜像）

新增了开发专用容器配置：`Dockerfile.dev` + `docker-compose.dev.yml`。

### 启动开发环境

```bash
FRONTEND_LOCAL_DIR=./<前端目录> BACKEND_LOCAL_DIR=./<后端目录> docker compose -f docker-compose.dev.yml up --build
```

特点：
- 挂载本地源码（`./frontend`、`./backend`）到容器内；
- 改代码后直接生效（前端走 dev server，后端走可配置启动命令）；
- 仍使用固定端口：前端 `18789`，后端 `5000`。

### 常用命令

```bash
# 后台启动
docker compose -f docker-compose.dev.yml up -d --build

# 查看日志
docker compose -f docker-compose.dev.yml logs -f

# 停止并清理
docker compose -f docker-compose.dev.yml down
```

### 按项目技术栈覆盖启动命令

在 `docker-compose.dev.yml` 里设置：
- `FRONTEND_DEV_CMD`（默认：`npm run dev -- --host 0.0.0.0 --port 18789`）
- `BACKEND_DEV_CMD`（默认：`python app.py`）

例如 Flask/FastAPI/Django 可替换为各自带热重载的启动命令。

## 代码更新后如何更新镜像

每次代码变更后，按以下流程：

1. 重新构建镜像（建议打新 tag）
   ```bash
   docker build -t hermes-offline:2026-05-09 \
     --build-arg FRONTEND_DIR=<你的前端目录> \
     --build-arg BACKEND_DIR=<你的后端目录> .
   ```
2. 停旧容器并删除
   ```bash
   docker rm -f hermes-offline
   ```
3. 用新镜像启动
   ```bash
   docker run -d --name hermes-offline -p 18789:18789 -p 5000:5000 hermes-offline:2026-05-09
   ```
4. （离线场景）重复 `save -> 拷贝 -> load -> run`

如果用 CI/CD，可把以上流程自动化为：构建 -> 推送镜像仓库 -> 拉取并滚动重启。
