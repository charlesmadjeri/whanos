FROM node:20.9-alpine

RUN apk add --no-cache bash
SHELL ["/bin/bash", "-c"]

WORKDIR /app

COPY . .

RUN if [ -f "package.json" ]; then \
        npm install --production && \
        rm package*.json; \
    fi

RUN rm -rf Dockerfile* .git*

CMD ["node", "."] 