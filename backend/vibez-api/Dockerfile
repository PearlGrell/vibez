FROM node:22-alpine3.18 AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

FROM node:22-alpine3.18

WORKDIR /app

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/protos /protos

RUN npm ci --omit=dev

EXPOSE 3000

CMD ["npm", "run", "start:prod"]
