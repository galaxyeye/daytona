FROM buildpack-deps:jammy-curl

ARG TARGETARCH

# common tools
RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends apt-utils vim htop telnet socat expect-dev \
    tini psmisc libgit2-dev \
    dos2unix \
    python3 python3-pip \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# build tools
RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends openjdk-11-jdk protobuf-compiler libprotobuf-dev

# Telepresence
RUN curl -fL https://app.getambassador.io/download/tel2oss/releases/download/v2.17.0/telepresence-linux-${TARGETARCH} -o /usr/local/bin/telepresence && \
    chmod a+x /usr/local/bin/telepresence

CMD ["tail", "-f", "/dev/null"]