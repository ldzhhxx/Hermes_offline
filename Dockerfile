# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS frontend-deps
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY frontend/ ./
RUN npm run build

FROM python:3.12-alpine AS backend-deps
WORKDIR /app/backend
COPY backend/requirements*.txt ./
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
COPY backend/ ./

FROM python:3.12-alpine
WORKDIR /app

RUN apk add --no-cache nodejs npm tini \
    && npm i -g serve@14.2.4 \
    && addgroup -S hermes && adduser -S hermes -G hermes

COPY --from=frontend-deps /app/frontend /app/frontend
COPY --from=backend-deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=backend-deps /usr/local/bin /usr/local/bin
COPY --from=backend-deps /app/backend /app/backend
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && chown -R hermes:hermes /app

USER hermes
EXPOSE 5000 18789
ENTRYPOINT ["/sbin/tini","--","/entrypoint.sh"]
