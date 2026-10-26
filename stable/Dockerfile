FROM debian:stable-slim@sha256:a717a33469731894e77e912ea7d714e27c2dc38ee6554fd1a3102e92999cfc66
ARG SECURITY_UPDATE_DATE=2026-10-24

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
