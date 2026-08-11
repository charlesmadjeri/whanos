FROM jenkins/jenkins:2.541.3-jdk17

ARG JENKINS_ADMIN_PASSWORD
ENV JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}
ENV JAVA_OPTS=-Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG=/opt/whanos/jenkins/casc/jenkins-config.yml
ENV JENKINS_URL=${JENKINS_URL}

USER root

RUN apt-get update && apt-get install -y lsb-release tree wget gettext-base \
    iputils-ping net-tools
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli

COPY jenkins /opt/whanos/jenkins

RUN chmod +x /opt/whanos/jenkins/scripts/*.sh
RUN mkdir -p /var/lib/jenkins/kube && \
    chown -R jenkins:jenkins /var/lib/jenkins/kube && \
    chmod 700 /var/lib/jenkins/kube
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/
RUN wget https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq

USER jenkins

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
# Avoid flaky geo mirrors (e.g. halifax) that reset connections during plugin install.
ENV JENKINS_UC_DOWNLOAD=https://ftp.belnet.be/mirror/jenkins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt \
    --jenkins-update-center https://updates.jenkins.io/update-center.json \
    --jenkins-plugin-info https://updates.jenkins.io/plugin-versions.json

COPY images /opt/whanos/images
