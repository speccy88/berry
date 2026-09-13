# Standalone Linux/x86-64 Berry/P2 builder; no serial device or network at runtime.
# Catalina is source-pinned by tools/bootstrap_catalina.py, not by this OS layer.
FROM debian:trixie-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash bison build-essential ca-certificates clang-19 dos2unix file flex \
        gawk gcc-multilib git libboost-dev libclang-rt-19-dev libncurses-dev \
        libreadline-dev make patch python3 python3-serial unzip xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10000 --shell /bin/bash berry \
    && mkdir -p /work \
    && chown berry:berry /work

ENV PYTHONDONTWRITEBYTECODE=1
USER 10000:10000
WORKDIR /work
CMD ["bash"]
