FROM node:22-alpine

WORKDIR /app

COPY package.json ./
COPY scripts/tools/serve.js ./scripts/tools/serve.js
COPY deploy/ ./deploy/

RUN pck_bytes="$(wc -c < ./deploy/index.pck)" \
    && if [ "$pck_bytes" -lt 1000000 ]; then \
        echo "deploy/index.pck is only ${pck_bytes} bytes; Git LFS content was not fetched" >&2; \
        exit 1; \
    fi

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8686
ENV SHUOGUANG_WEB_ROOT=/app/deploy
ENV LLM_PROVIDER=cnb

EXPOSE 8686

CMD ["node", "scripts/tools/serve.js"]
