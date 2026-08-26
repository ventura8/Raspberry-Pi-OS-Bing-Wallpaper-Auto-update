FROM debian:trixie-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

ARG DEBIAN_SNAPSHOT=20260825T000000Z
ARG HADOLINT_VERSION=v2.15.1
ARG TARGETARCH

RUN rm -f /etc/apt/sources.list.d/* \
    && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99snapshot \
    && snapshot_main="http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}" \
    && snapshot_security="http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}" \
    && printf 'deb [check-valid-until=no] %s trixie main\n' "$snapshot_main" > /etc/apt/sources.list \
    && printf 'deb [check-valid-until=no] %s trixie-updates main\n' "$snapshot_main" >> /etc/apt/sources.list \
    && printf 'deb [check-valid-until=no] %s trixie-security main\n' "$snapshot_security" >> /etc/apt/sources.list

# Install dependencies
# bats: testing framework
# curl: used by script
# procps: for pgrep used in script
# ca-certificates: to ensure curl works with https
RUN apt-get update && apt-get install -y --no-install-recommends \
    bats=1.11.1-1 \
    bash=5.2.37-2+b9 \
    curl=8.14.1-2+deb13u4 \
    gawk=1:5.2.1-2+b1 \
    grep=3.11-4 \
    procps=2:4.0.4-9 \
    ca-certificates=20250419 \
    dos2unix=7.5.2-1 \
    kcov=43+dfsg-1+b4 \
    shellcheck=0.10.0-1 \
    shfmt=3.8.0-1+b8 \
    python3=3.13.5-1 \
    python3-pip=25.1.1+dfsg-1 \
    python3-venv=3.13.5-1 \
    nodejs=20.19.2+dfsg-1+deb13u2 \
    npm=9.2.0~ds1-3 \
    git=1:2.47.3-0+deb13u1 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --break-system-packages \
    mypy==2.3.1 \
    ruff==0.16.4 \
    yamllint==1.38.0 \
    && npm install --global markdownlint-cli2@0.23.2

RUN arch="${TARGETARCH:-}" \
        && if [ -z "$arch" ]; then arch="$(dpkg --print-architecture)"; fi \
        && case "$arch" in \
            amd64) hadolint_arch="x86_64"; hadolint_sha256="c7187db94eeeeca956519a6af171adc31453941a1e777961f6e680f697c8c507" ;; \
            arm64) hadolint_arch="arm64"; hadolint_sha256="f6198ef8090f404dbb771abfee086eb8c48ac177f30da7fd3510aca35b344b5d" ;; \
            *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
        esac \
        && hadolint_url="https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-linux-${hadolint_arch}" \
        && curl -fsSL "$hadolint_url" -o /usr/local/bin/hadolint \
    && printf '%s  %s\n' "$hadolint_sha256" /usr/local/bin/hadolint > /tmp/hadolint.sha256 \
    && sha256sum -c /tmp/hadolint.sha256 \
    && rm -f /tmp/hadolint.sha256 \
        && chmod +x /usr/local/bin/hadolint

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Convert line endings to Unix style (for Windows hosts)
RUN dos2unix ./*.sh ./tests/*.bats ./tests/mocks/* ./tests/*.py ./scripts/*.py ./scripts/*.sh

# Make scripts executable
RUN chmod +x ./*.sh ./tests/*.sh ./tests/mocks/* ./scripts/*.py ./scripts/*.sh

# Run tests by default
CMD ["bats", "tests/"]
