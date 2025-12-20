FROM debian:trixie-slim

# Install dependencies
# bats: testing framework
# curl: used by script
# procps: for pgrep used in script
# ca-certificates: to ensure curl works with https
RUN apt-get update && apt-get install -y \
    bats \
    curl \
    grep \
    procps \
    ca-certificates \
    dos2unix \
    kcov \
    python3 \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Convert line endings to Unix style (for Windows hosts)
RUN dos2unix *.sh tests/*.bats tests/mocks/* tests/*.py

# Make scripts executable
RUN chmod +x *.sh tests/*.sh tests/mocks/*

# Run tests by default
CMD ["bats", "tests/"]
