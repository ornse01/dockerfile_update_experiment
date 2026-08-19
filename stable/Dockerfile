FROM debian:stable-slim@sha256:1710bde34461551a19a47c787885ec9ad7058d9a5bead2affb8d088fa2f8502b
ARG SECURITY_UPDATE_DATE=2026-08-19

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
