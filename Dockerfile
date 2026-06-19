FROM node:22-alpine

WORKDIR /app

COPY package.json ./
COPY scripts/tools/serve.js ./scripts/tools/serve.js
COPY deploy/ ./deploy/

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8686
ENV SHUOGUANG_WEB_ROOT=/app/deploy
ENV LLM_PROVIDER=cnb

EXPOSE 8686

CMD ["node", "scripts/tools/serve.js"]
