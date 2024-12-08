FROM maven:3.9-amazoncorretto-21

SHELL ["/bin/bash", "-c"]

WORKDIR /app

COPY . .

RUN if [ -f "pom.xml" ]; then \
        mvn dependency:resolve && \
        mvn package && \
        mv target/app.jar /app.jar && \
        rm -rf * && \
        mv /app.jar .; \
    fi

RUN rm -rf Dockerfile* .git*

CMD ["java", "-jar", "app.jar"] 