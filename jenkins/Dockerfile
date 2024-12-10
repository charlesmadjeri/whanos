FROM jenkins/jenkins:2.479.2-jdk17

ARG JENKINS_ADMIN_PASSWORD
ENV JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /jenkins/casc/jenkins-config.yml
ENV JENKINS_URL=${JENKINS_URL}

USER root
RUN apt-get update && apt-get install -y lsb-release tree
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli

USER jenkins

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY images /images
COPY jenkins /jenkins