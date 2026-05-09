# syntax=docker/dockerfile:1.7

FROM python:3.11-slim-bookworm AS backend-deps
WORKDIR /build

# Create virtualenv and install backend dependencies (cached).
COPY hermes-agent/ /build/hermes-agent/
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip setuptools wheel \
    && if [ -f /build/hermes-agent/requirements.txt ]; then /opt/venv/bin/pip install --no-cache-dir -r /build/hermes-agent/requirements.txt; fi

FROM node:20-bookworm-slim AS frontend-deps
WORKDIR /build/hermes-webui
COPY hermes-webui/package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; \
   elif [ -f package.json ]; then npm install; \
   else echo "No package.json found, skip npm install"; fi
COPY hermes-webui/ ./
RUN if [ -f package.json ]; then npm run build || true; fi

FROM python:3.11-slim-bookworm
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# Copy Node runtime from official Node image to avoid apt metadata and keep image smaller.
COPY --from=node:20-bookworm-slim /usr/local /usr/local

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HERMES_BACKEND_PORT=5000 \
    HERMES_FRONTEND_PORT=18789

COPY --from=backend-deps /opt/venv /opt/venv
COPY hermes-agent/ /app/hermes-agent/
COPY --from=frontend-deps /build/hermes-webui /app/hermes-webui/

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000 18789
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
