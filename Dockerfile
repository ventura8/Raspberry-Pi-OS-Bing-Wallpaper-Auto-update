FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_SNAPSHOT=20260920T000000Z
ARG HADOLINT_VERSION=v2.15.1
ARG SHELLCHECK_VERSION=v0.11.0
ARG SHFMT_VERSION=v3.14.1
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
    bash=5.2.37-2+b10 \
    bats=1.11.1-1 \
    ca-certificates=20250419 \
    curl=8.14.1-2+deb13u5 \
    dos2unix=7.5.2-1 \
    gawk=1:5.2.1-2+b1 \
    git=1:2.47.3-0+deb13u1 \
    grep=3.11-4 \
    kcov=43+dfsg-1+b4 \
    nodejs=20.19.2+dfsg-1+deb13u2 \
    npm=9.2.0~ds1-3 \
    procps=2:4.0.4-9 \
    python3=3.13.5-1 \
    python3-pip=25.1.1+dfsg-1 \
    python3-venv=3.13.5-1 \
    xz-utils=5.8.1-1+deb13u1 \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --break-system-packages \
    mypy==2.3.1 \
    ruff==0.16.8 \
    yamllint==1.38.0 \
    && npm install --global --ignore-scripts markdownlint-cli2@0.23.3

RUN arch="${TARGETARCH:-}" \
        && if [ -z "$arch" ]; then arch="$(dpkg --print-architecture)"; fi \
        && case "$arch" in \
            amd64) hadolint_arch="x86_64"; hadolint_sha256="c7187db94eeeeca956519a6af171adc31453941a1e777961f6e680f697c8c507" ;; \
            arm64) hadolint_arch="arm64"; hadolint_sha256="f6198ef8090f404dbb771abfee086eb8c48ac177f30da7fd3510aca35b344b5d" ;; \
            *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
        esac \
        && hadolint_url="https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-linux-${hadolint_arch}" \
        && curl --proto '=https' --tlsv1.2 -fsSL "$hadolint_url" -o /usr/local/bin/hadolint \
    && printf '%s  %s\n' "$hadolint_sha256" /usr/local/bin/hadolint > /tmp/hadolint.sha256 \
    && sha256sum -c /tmp/hadolint.sha256 \
    && rm -f /tmp/hadolint.sha256 \
        && chmod +x /usr/local/bin/hadolint

RUN arch="${TARGETARCH:-}" \
    && if [ -z "$arch" ]; then arch="$(dpkg --print-architecture)"; fi \
    && case "$arch" in \
        amd64) sc_arch="x86_64"; sc_sha256="8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"; \
            shfmt_sha256="76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf" ;; \
        arm64) sc_arch="aarch64"; sc_sha256="12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588"; \
            shfmt_sha256="5f2db09dae91fca848f7adbdd014632e921a383863a2ad7e0450ad3aba0c6489" ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac \
    && sc_url="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}" \
    && curl --proto '=https' --tlsv1.2 -fsSL "${sc_url}/shellcheck-${SHELLCHECK_VERSION}.linux.${sc_arch}.tar.xz" \
        -o /tmp/shellcheck.tar.xz \
    && printf '%s  %s\n' "$sc_sha256" /tmp/shellcheck.tar.xz | sha256sum -c - \
    && tar -xJf /tmp/shellcheck.tar.xz -C /tmp \
    && install -m 0755 "/tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck \
    && rm -rf /tmp/shellcheck.tar.xz "/tmp/shellcheck-${SHELLCHECK_VERSION}" \
    && shfmt_url="https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}" \
    && curl --proto '=https' --tlsv1.2 -fsSL "${shfmt_url}/shfmt_${SHFMT_VERSION}_linux_${arch}" \
        -o /usr/local/bin/shfmt \
    && printf '%s  %s\n' "$shfmt_sha256" /usr/local/bin/shfmt | sha256sum -c - \
    && chmod +x /usr/local/bin/shfmt

# Set working directory
WORKDIR /app

# Copy only what the quality gates and test suites need
COPY bing_wallpaper.sh install.sh uninstall.sh pyproject.toml ./
COPY scripts ./scripts
COPY tests ./tests

# Convert line endings to Unix style (for Windows hosts) and make scripts executable
RUN dos2unix ./*.sh ./tests/*.bats ./tests/mocks/* ./tests/*.py ./scripts/*.py ./scripts/*.sh \
    && chmod +x ./*.sh ./tests/*.sh ./tests/mocks/* ./scripts/*.py ./scripts/*.sh

# Run tests by default
CMD ["bats", "tests/"]
