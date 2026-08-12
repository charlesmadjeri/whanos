FROM jenkins/jenkins:2.541.3-jdk17

# Admin password and registry secrets come from runtime env_file / EnvironmentFile
# only — never bake them into image layers via ARG/ENV.
ENV JAVA_OPTS=-Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG=/opt/whanos/jenkins/casc/jenkins-config.yml

USER root

RUN apt-get update && apt-get install -y lsb-release tree wget gettext-base \
    iputils-ping net-tools python3
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli

COPY jenkins /opt/whanos/jenkins

RUN chmod +x /opt/whanos/jenkins/scripts/*.sh /opt/whanos/jenkins/scripts/*.py
RUN mkdir -p /var/lib/jenkins/kube && \
    chown -R jenkins:jenkins /var/lib/jenkins/kube && \
    chmod 700 /var/lib/jenkins/kube

# Pinned tool versions + SHA256 (linux/amd64)
ARG KUBECTL_VERSION=v1.31.0
ARG KUBECTL_SHA256=7c27adc64a84d1c0cc3dcf7bf4b6e916cc00f3f576a2dbac51b318d926032437
ARG DOCTL_VERSION=1.120.0
ARG DOCTL_SHA256=4d6bddfa2480ff10a7704a26eddf5a9d1c568653fc50cc2eb033522486b9c7cd
ARG YQ_VERSION=v4.35.1
ARG YQ_SHA256=bd695a6513f1196aeda17b174a15e9c351843fb1cef5f9be0af170f2dd744f08

RUN curl -fsSLo /tmp/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && echo "${KUBECTL_SHA256}  /tmp/kubectl" | sha256sum -c - \
    && install -m 0755 /tmp/kubectl /usr/local/bin/kubectl \
    && rm -f /tmp/kubectl

RUN curl -fsSLo /tmp/doctl.tgz \
      "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz" \
    && echo "${DOCTL_SHA256}  /tmp/doctl.tgz" | sha256sum -c - \
    && tar -xzf /tmp/doctl.tgz -C /usr/local/bin doctl \
    && chmod +x /usr/local/bin/doctl \
    && rm -f /tmp/doctl.tgz

RUN curl -fsSLo /tmp/yq \
      "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    && echo "${YQ_SHA256}  /tmp/yq" | sha256sum -c - \
    && install -m 0755 /tmp/yq /usr/bin/yq \
    && rm -f /tmp/yq

USER jenkins

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
# Avoid flaky geo mirrors (e.g. halifax) that reset connections during plugin install.
ENV JENKINS_UC_DOWNLOAD=https://ftp.belnet.be/mirror/jenkins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt \
    --jenkins-update-center https://updates.jenkins.io/update-center.json \
    --jenkins-plugin-info https://updates.jenkins.io/plugin-versions.json

COPY images /opt/whanos/images
