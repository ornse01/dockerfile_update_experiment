FROM debian:stable-slim@sha256:eb593cf2c358cacef45ca0a424bbc7d30cfa3466265fc2662b9466a0ca6ba1c5
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
