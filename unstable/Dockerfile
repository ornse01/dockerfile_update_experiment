FROM debian:unstable-slim@sha256:399823d4e7583f7505b4e55c5a0324e20510ec53954e43aa90519a6b0bf3366c
# SECURITY_UPDATE: 2026-07-11

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    wget \
    vim \
    procps \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

CMD ["bash"]
