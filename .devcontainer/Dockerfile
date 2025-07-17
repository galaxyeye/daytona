FROM buildpack-deps:jammy-curl

ARG TARGETARCH

ENV TZ=Asia/Shanghai \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.local/bin:$PATH"

# Install all system packages in a single layer
RUN apt-get update && apt-get -y install --no-install-recommends \
    # common tools
    apt-utils \
    vim \
    htop \
    telnet \
    socat \
    expect-dev \
    tini \
    psmisc \
    libgit2-dev \
    dos2unix \
    # Python and build tools
    python3 \
    python3-pip \
    openjdk-11-jdk \
    protobuf-compiler \
    libprotobuf-dev \
    # Locale support
    locales \
    && locale-gen zh_CN.UTF-8 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - \
    && ln -s /root/.local/bin/poetry /usr/local/bin/poetry

# Install Telepresence
RUN curl -fL https://app.getambassador.io/download/tel2oss/releases/download/v2.17.0/telepresence-linux-${TARGETARCH} -o /usr/local/bin/telepresence \
    && chmod a+x /usr/local/bin/telepresence

# Process shell scripts
RUN find / -type f -name "*.sh" 2>/dev/null -exec dos2unix {} \; -exec chmod +x {} \; || true

CMD ["tail", "-f", "/dev/null"]
