FROM ubuntu:20.04 AS install

RUN apt update -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    docker.io \
    fuse-overlayfs \
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

# Add user
RUN groupadd -g 1000 armonik && \
    useradd -m -g armonik -u 1000 -d /home/armonik armonik && \
    usermod -a -G docker,sudo armonik && \
    passwd -d armonik && \
    su armonik -c 'mkdir /home/armonik/.kube && ln -s /etc/rancher/k3s/k3s.yaml /home/armonik/.kube/config'

COPY docker-init.sh /usr/local/bin/init

COPY --chown=1000:1000 .dockerignore Makefile LICENSE *.md  /armonik/
COPY --chown=1000:1000 deployment /armonik/deployment
COPY --chown=1000:1000 docs /armonik/docs
COPY --chown=1000:1000 examples /armonik/examples
COPY --chown=1000:1000 local_deployment /armonik/local_deployment
COPY --chown=1000:1000 redis_certificates /armonik/redis_certificates
COPY --chown=1000:1000 source /armonik/source

ENTRYPOINT ["/usr/local/bin/init"]

WORKDIR /armonik

USER armonik

ENV ARMONIK_TASKS_TABLE_SERVICE=MongoDB
ENV ARMONIK_QUEUE_SERVICE=RSMQ
ENV ARMONIK_NUGET_REPOS=/armonik/dist/dotnet5.0
ENV ARMONIK_REDIS_CERTIFICATES_DIRECTORY=/armonik/redis_certificates
ENV ARMONIK_API_GATEWAY_SERVICE=NGINX

# This could be done in Docker build, but enlarges the image by ~200MB
#RUN make init-grid-local-deployment

ARG BUILD_ID=XXXX
ARG DOCKER_REGISTRY=dockerhubaneo

ENV ARMONIK_TAG=armonik-dev-${BUILD_ID}
ENV ARMONIK_DOCKER_REGISTRY=${DOCKER_REGISTRY}

RUN make mock-config-local-dotnet5.0 && \
    make k8s-jobs
