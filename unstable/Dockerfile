FROM debian:unstable-slim@sha256:8c99fc3b4617c61eaa16d4436748f779e9a6354b004117814453a23a0dc35279
ARG SECURITY_UPDATE_DATE=2026-09-13

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
