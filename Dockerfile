# syntax=docker/dockerfile:1.7

ARG FRONTEND_DIR=.
ARG BACKEND_DIR=.

FROM node:22-alpine AS frontend-deps
ARG FRONTEND_DIR
WORKDIR /src
COPY . /src
RUN if [ -f "/src/${FRONTEND_DIR}/package-lock.json" ]; then \
      npm --prefix "/src/${FRONTEND_DIR}" ci && npm --prefix "/src/${FRONTEND_DIR}" run build; \
    elif [ -f "/src/${FRONTEND_DIR}/package.json" ]; then \
      npm --prefix "/src/${FRONTEND_DIR}" install && npm --prefix "/src/${FRONTEND_DIR}" run build; \
    else \
      mkdir -p /src/${FRONTEND_DIR}/dist; \
      echo "[WARN] No package.json found in FRONTEND_DIR=${FRONTEND_DIR}; creating empty dist."; \
    fi

FROM python:3.12-alpine AS backend-deps
ARG BACKEND_DIR
WORKDIR /src
COPY . /src
RUN if [ -f "/src/${BACKEND_DIR}/requirements.txt" ]; then \
      pip install --no-cache-dir -r "/src/${BACKEND_DIR}/requirements.txt"; \
    else \
      echo "[WARN] No requirements.txt found in BACKEND_DIR=${BACKEND_DIR}; skipping pip install."; \
    fi

FROM python:3.12-alpine
ARG FRONTEND_DIR
ARG BACKEND_DIR
WORKDIR /app

RUN apk add --no-cache nodejs npm tini \
    && npm i -g serve@14.2.4 \
    && addgroup -S hermes && adduser -S hermes -G hermes

COPY --from=frontend-deps /src/${FRONTEND_DIR} /app/frontend
COPY --from=backend-deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=backend-deps /usr/local/bin /usr/local/bin
COPY --from=backend-deps /src/${BACKEND_DIR} /app/backend
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && chown -R hermes:hermes /app

USER hermes
EXPOSE 5000 18789
ENTRYPOINT ["/sbin/tini","--","/entrypoint.sh"]
