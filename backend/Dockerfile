FROM node:22-alpine3.18 AS api-builder
WORKDIR /api
RUN apk add --no-cache python3 make g++
COPY vibez-api/package*.json ./
RUN npm ci
COPY vibez-api/ ./
RUN npm run build && npm prune --omit=dev

FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY vibez-backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt && pip install --no-cache-dir -U yt-dlp
COPY vibez-backend/ ./grpc/

COPY --from=api-builder /api/dist ./api/dist
COPY --from=api-builder /api/node_modules ./api/node_modules
COPY --from=api-builder /api/package*.json ./api/
COPY vibez-api/protos /protos

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV PYTHONUNBUFFERED=1 \
    GRPC_URL=localhost:50051 \
    STREAM_RELAY_URL=http://localhost:8080

EXPOSE 3000
CMD ["/app/start.sh"]
