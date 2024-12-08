FROM gcc:13

SHELL ["/bin/bash", "-c"]

WORKDIR /app

COPY . .

RUN if [ -f "Makefile" ]; then \
        make && \
        mv compiled-app /compiled-app && \
        rm -rf /app/*; \
    fi

RUN rm -rf Dockerfile* .git*

CMD ["/compiled-app"] 