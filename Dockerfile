FROM debian:12.10-slim

ARG RUNNER_DOWNLOAD_BASE_URL="https://github.com/actions/runner/releases/download"
ARG RUNNER_ARCH="arm64"
ARG RUNNER_VERSION="2.323.0"
ARG RUNNER_TAR="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get clean autoclean \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    jq \
    libffi-dev \
    libicu-dev \
    libssl-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv

RUN useradd -m docker

RUN mkdir -p /home/docker/actions-runner

RUN cd /home/docker/actions-runner \
 && curl -O -L "${RUNNER_DOWNLOAD_BASE_URL}/v${RUNNER_VERSION}/${RUNNER_TAR}" \
 && tar xzf "./${RUNNER_TAR}" \
 && rm "./${RUNNER_TAR}"

# install some additional dependencies
RUN chown -R docker ~docker \
 && /home/docker/actions-runner/bin/installdependencies.sh

WORKDIR /home/docker/actions-runner

COPY start.sh start.sh

RUN chmod +x start.sh

USER docker

ENTRYPOINT ["./start.sh"]
