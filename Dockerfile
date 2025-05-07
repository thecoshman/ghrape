FROM ubuntu:24.10

# set the github runner version
ARG RUNNER_VERSION="2.323.0"

RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get clean autoclean \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    jq \
    libffi-dev \
    libicu \
    libssl-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv

RUN useradd -m docker

RUN mkdir -p /home/docker/actions-runner

RUN cd /home/docker/actions-runner \
 && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
 && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
 && rm ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R docker ~docker \
 && /home/docker/actions-runner/bin/installdependencies.sh

WORKDIR /home/docker/actions-runner

COPY start.sh start.sh

RUN chmod +x start.sh

USER docker

ENTRYPOINT ["./start.sh"]
