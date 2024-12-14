FROM node:20.9-alpine

RUN apk add --no-cache bash
SHELL ["/bin/bash", "-c"]

RUN npm install -g typescript

WORKDIR /app

COPY . .

RUN if [ -f "package.json" ]; then \
        npm install --production && \
        rm package*.json; \
    fi

RUN if [ -f "tsconfig.json" ]; then \
        npm install --save-dev typescript && \
        npx tsc && \
        rm -rf $(find . -name "*.ts" ! -name "*.d.ts") && \
        npm uninstall typescript; \
    fi

RUN rm -rf Dockerfile* .git*

CMD ["node", "."] 