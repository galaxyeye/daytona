FROM buildpack-deps:jammy-curl

ARG TARGETARCH

ENV LC_ALL=zh_CN.UTF-8

# common tools
RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends apt-utils vim htop telnet socat expect-dev \
    tini psmisc libgit2-dev \
    dos2unix \
    python3 python3-pip \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - \
    && ln -s /root/.local/bin/poetry /usr/local/bin/poetry
ENV PATH="/root/.local/bin:$PATH"

# find all bash scripts, apply dos2unix, and make them executable
RUN find / -type f -name "*.sh" -exec dos2unix {} \; && find / -type f -name "*.sh" -exec chmod +x {} \;

# build tools
RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends openjdk-11-jdk protobuf-compiler libprotobuf-dev

# Telepresence
RUN curl -fL https://app.getambassador.io/download/tel2oss/releases/download/v2.17.0/telepresence-linux-${TARGETARCH} -o /usr/local/bin/telepresence && \
    chmod a+x /usr/local/bin/telepresence

CMD ["tail", "-f", "/dev/null"]
