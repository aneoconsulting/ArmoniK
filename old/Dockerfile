FROM ubuntu:20.04

RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    docker.io \
    fuse-overlayfs \
    jq \
    make \
    sudo \
    unzip \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Kubernetes
RUN curl -fsSL https://github.com/k3s-io/k3s/releases/latest/download/k3s -o /usr/local/bin/k3s && \
    chmod 755 /usr/local/bin/k3s && \
    ln -s k3s /usr/local/bin/kubectl && \
    ln -s k3s /usr/local/bin/crictl

# Terraform
RUN TERRAFORM_VERSION="$(curl -fsS https://github.com/hashicorp/terraform/releases/latest | sed 's|^.*href=".*/releases/tag/v\(.*\)">.*$|\1|')" && \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip && \
    ( cd /tmp ; unzip terraform.zip ; ) && \
    install -m 755 /tmp/terraform -t /usr/local/bin/ && \
    rm -f /tmp/terraform.zip /tmp/terraform

# Helm
RUN HELM_VERSION="$(curl -fsS https://github.com/helm/helm/releases/latest | sed 's|^.*href=".*/releases/tag/v\(.*\)">.*$|\1|')" && \
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar -xzf - -C /tmp && \
    install -m 755 /tmp/linux-amd64/helm -t /usr/local/bin && \
    rm -rf /tmp/linux-*

# Docker config
RUN echo '{"storage-driver": "fuse-overlayfs"}' > /etc/docker/daemon.json

ARG MODE=user

# Dotnet and python install for 'dev' MODE
RUN if [ "${MODE}" = dev ]; then \
      apt update -y && \
      DEBIAN_FRONTEND=noninteractive apt install -y \
        apt-transport-https \
        ca-certificates \
        gnupg \
        software-properties-common \
        python3-pip \
        python-is-python3 \
      && \
      curl -fsSL https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -o /tmp/pkg-microsoft.deb && \
      dpkg -i /tmp/pkg-microsoft.deb && \
      rm -f /tmp/pkg-microsoft.deb && \
      apt update -y && \
      apt install -y dotnet-sdk-5.0 && \
      apt clean && rm -rf /var/lib/apt/lists/* \
    ;fi

# Add user
RUN groupadd -g 1000 armonik-components && \
    useradd -m -g armonik-components -u 1000 -d /home/armonik-components armonik-components && \
    usermod -a -G docker,sudo armonik-components && \
    passwd -d armonik-components && \
    su armonik-components -c 'mkdir /home/armonik-components/.kube && ln -s /etc/rancher/k3s/k3s.yaml /home/armonik-components/.kube/config'

COPY docker-init.sh /usr/local/bin/init

COPY --chown=1000:1000 requirements.txt /armonik/

RUN if [ "${MODE}" = dev ]; then \
      pip install -r /armonik-components/requirements.txt \
    ;fi

COPY --chown=1000:1000 ../.dockerignore Makefile LICENSE *.md nuget-versions.txt /armonik/
COPY --chown=1000:1000 applications /armonik/applications
COPY --chown=1000:1000 deployment /armonik/deployment
COPY --chown=1000:1000 ../docs /armonik/docs
COPY --chown=1000:1000 local_deployment /armonik/local_deployment
COPY --chown=1000:1000 redis_certificates /armonik/redis_certificates
COPY --chown=1000:1000 ../source /armonik/source

ENTRYPOINT ["/usr/local/bin/init"]

WORKDIR /armonik

USER armonik

ENV ARMONIK_TASKS_TABLE_SERVICE=MongoDB
ENV ARMONIK_QUEUE_SERVICE=RSMQ
ENV ARMONIK_NUGET_REPOS=/armonik/dist/dotnet5.0
ENV ARMONIK_REDIS_CERTIFICATES_DIRECTORY=/armonik/redis_certificates
ENV ARMONIK_API_GATEWAY_SERVICE=NGINX
ENV ARMONIK_CLUSTER_CONFIG=local
ENV ARMONIK_IMAGE_PULL_POLICY=IfNotPresent

# This could be done in Docker build, but enlarges the image by ~200MB
#RUN make init-grid-local-deployment

# You can either specify BUILD_ID or the complete TAG
ARG DOCKER_REGISTRY=dockerhubaneo
ARG BUILD_ID=XXXX
ARG TAG=armonik-dev-${BUILD_ID}
ARG BUILD_TYPE=Release

ENV ARMONIK_DOCKER_MODE=${MODE}
ENV ARMONIK_TAG=${TAG}
ENV ARMONIK_DOCKER_REGISTRY=${DOCKER_REGISTRY}
ENV BUILD_TYPE=${BUILD_TYPE}

RUN if [ "${MODE}" != dev ]; then \
      make k8s-jobs ; \
    fi

ARG APP=ArmonikSamples
ENV ARMONIK_APPLICATION_NAME=${APP}
