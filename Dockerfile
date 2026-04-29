# syntax=docker/dockerfile:1.6

FROM ubuntu:22.04

ARG TARGETARCH
ENV VERSION=0.6.0
ENV TZ=Asia/Shanghai
ENV GITEA_INSTANCE_URL=https://gitea.com
ENV GITEA_RUNNER_REGISTRATION_TOKEN=

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# =========================
# base tools
# =========================
RUN apt update && apt install -y --no-install-recommends \
    curl \
    git \
    jq \
    ca-certificates \
    tzdata \
    wget \
    unzip \
    gnupg \
    nodejs \
    && rm -rf /var/lib/apt/lists/*


# =========================
# arch mapping
# =========================
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ARCH="amd64" ;; \
        arm64) ARCH="arm64" ;; \
        arm) ARCH="arm" ;; \
        *) echo "unsupported arch: ${TARGETARCH}" && exit 1 ;; \
    esac; \
    echo "ARCH=${ARCH}" > /tmp/arch.env

# =========================
# yq
# =========================
RUN set -eux; \
    . /tmp/arch.env; \
    curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}" \
      -o /usr/local/bin/yq; \
    chmod +x /usr/local/bin/yq

# =========================
# act_runner
# =========================
RUN set -eux; \
    . /tmp/arch.env; \
    curl -L "https://dl.gitea.com/act_runner/${VERSION}/act_runner-${VERSION}-linux-${ARCH}" \
      -o /usr/local/bin/act_runner; \
    chmod +x /usr/local/bin/act_runner

# =========================
# kubectl
# =========================
RUN set -eux; \
    . /tmp/arch.env; \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"; \
    chmod +x kubectl; \
    mv kubectl /usr/local/bin/

# =========================
# helm
# =========================
RUN set -eux; \
    . /tmp/arch.env; \
    HELM_VERSION="v3.14.0"; \
    curl -L "https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz" -o helm.tgz; \
    tar -zxvf helm.tgz; \
    mv linux-${ARCH}/helm /usr/local/bin/helm; \
    chmod +x /usr/local/bin/helm; \
    rm -rf helm.tgz linux-${ARCH}

# =========================
# flux
# =========================
RUN set -eux; \
    . /tmp/arch.env; \
    FLUX_VERSION="2.3.0"; \
    curl -s https://fluxcd.io/install.sh | bash

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# =========================
# cleanup
# =========================
RUN rm -f /tmp/arch.env

WORKDIR /opt/act-runner

CMD ["/entrypoint.sh"]
