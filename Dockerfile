# ====================
# Ubuntu-based Dockerfile with Project-driven Dependencies
# ====================
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:$PATH"

# Update system and install essential build tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create app directory and copy project
WORKDIR /app
COPY . .

# Install mise for version management
RUN curl https://mise.run | sh && \
    echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc

# Trust mise configuration files
RUN ~/.local/bin/mise trust

# Install tools defined in mise.toml
RUN ~/.local/bin/mise install

# Setup environment for mise tools
ENV PATH="/root/.local/share/mise/installs/node/20.18.1/bin:/root/.local/share/mise/installs/go/1.23.5/bin:/root/.local/share/mise/installs/python/3.11.11/bin:$PATH"
ENV GOROOT="/root/.local/share/mise/installs/go/1.23.5"
ENV GOPATH="/go"

# Install Node.js dependencies using project configuration
RUN ~/.local/bin/mise exec -- corepack enable && \
    ~/.local/bin/mise exec -- yarn install

# Install Python dependencies if present
RUN if [ -f "pyproject.toml" ]; then \
        ~/.local/bin/mise exec -- pip install poetry && \
        ~/.local/bin/mise exec -- poetry config virtualenvs.create false && \
        ~/.local/bin/mise exec -- poetry install --only=main; \
    elif [ -f "requirements.txt" ]; then \
        ~/.local/bin/mise exec -- pip install -r requirements.txt; \
    fi

# Download Go modules if present
RUN if [ -f "go.work" ] || [ -f "go.mod" ]; then \
        ~/.local/bin/mise exec -- go mod download; \
    fi

# Run prebuild steps (download xterm, etc.)
RUN ~/.local/bin/mise exec -- yarn download-xterm-with-fallback

# Try to get verbose output for debugging NX issues
RUN ~/.local/bin/mise exec -- yarn build:production --verbose || \
    ~/.local/bin/mise exec -- yarn build --verbose || \
    echo "Build failed, but continuing..."

# Expose common ports
EXPOSE 3000 5556

# Set default command to use mise environment
# CMD ["bash", "-c", "eval \"$(~/.local/bin/mise activate bash)\" && yarn serve:production || yarn serve || bash"]
CMD ["tail", "-f", "/dev/null"]
