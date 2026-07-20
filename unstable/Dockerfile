FROM debian:unstable-slim@sha256:153e7023d3501a4a980f54fd3e8560c029109bb1a3475fcc5047fc948da553ab
# SECURITY_UPDATE: 2026-07-11

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
