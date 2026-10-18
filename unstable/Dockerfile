FROM debian:unstable-slim@sha256:c08a0224cfc8b218e619427b09aac70939ec5ac68d91a58a558b7c20e5f0d280
ARG SECURITY_UPDATE_DATE=2026-10-18

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    wget \
    vim \
    procps \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

CMD ["bash"]
