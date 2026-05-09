# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS hermes-webui-deps
WORKDIR /app/hermes-webui
COPY hermes-webui/package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY hermes-webui/ ./
RUN npm run build

FROM python:3.12-alpine AS hermes-agent-deps
WORKDIR /app/hermes-agent
COPY hermes-agent/requirements*.txt ./
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
COPY hermes-agent/ ./

FROM python:3.12-alpine
WORKDIR /app

RUN apk add --no-cache nodejs npm tini \
    && npm i -g serve@14.2.4 \
    && addgroup -S hermes && adduser -S hermes -G hermes

COPY --from=hermes-webui-deps /app/hermes-webui /app/hermes-webui
COPY --from=hermes-agent-deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=hermes-agent-deps /usr/local/bin /usr/local/bin
COPY --from=hermes-agent-deps /app/hermes-agent /app/hermes-agent
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && chown -R hermes:hermes /app

USER hermes
EXPOSE 5000 18789
ENTRYPOINT ["/sbin/tini","--","/entrypoint.sh"]
