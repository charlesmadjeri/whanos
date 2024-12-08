FROM python:3.12-alpine

RUN apk add --no-cache bash
SHELL ["/bin/bash", "-c"]

WORKDIR /app

COPY . .

RUN if [ -f "requirements.txt" ]; then \
        pip install -r requirements.txt && \
        rm requirements.txt; \
    fi

RUN rm -rf Dockerfile* .git*

CMD ["python", "-m", "app"] 