FROM debian:12.11-slim

ARG RUNNER_DOWNLOAD_BASE_URL="https://github.com/actions/runner/releases/download"
ARG RUNNER_ARCH="arm64"
ARG RUNNER_VERSION="2.325.0"
ARG RUNNER_TAR="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get clean autoclean \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
    libffi-dev \
    libicu-dev \
    libssl-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv

RUN install -m 0755 -d /etc/apt/keyrings

RUN curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc

RUN chmod a+r /etc/apt/keyrings/docker.asc

RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get clean autoclean \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin

RUN useradd -m docker

RUN mkdir -p /home/docker/actions-runner

RUN cd /home/docker/actions-runner \
 && curl -O -L "${RUNNER_DOWNLOAD_BASE_URL}/v${RUNNER_VERSION}/${RUNNER_TAR}" \
 && tar xzf "./${RUNNER_TAR}" \
 && rm "./${RUNNER_TAR}"

RUN chown -R docker ~docker \
 && /home/docker/actions-runner/bin/installdependencies.sh

WORKDIR /home/docker/actions-runner

COPY start.sh start.sh

RUN chmod +x start.sh

USER docker

ENTRYPOINT ["./start.sh"]

LABEL org.opencontainers.image.vendor="thecoshman" \
    org.opencontainers.image.source="https://github.com/thecoshman/ghrape" \
    org.opencontainers.image.title="Ghrape" \
    org.opencontainers.image.description="ARM based runner for GHA" \
    org.opencontainers.image.documentation="https://github.com/thecoshman/ghrape"
