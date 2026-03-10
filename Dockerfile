FROM debian:bookworm-slim

# Install minimal dependencies + Tectonic runtime libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget ca-certificates bash curl \
    libfontconfig1 libfreetype6 libgraphite2-3 \
    libharfbuzz0b libicu72 libssl3 && \
    rm -rf /var/lib/apt/lists/*

# Download and install PicoClaw binary
RUN wget -q https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_Linux_x86_64.tar.gz -O /tmp/picoclaw.tar.gz && \
    tar -xzf /tmp/picoclaw.tar.gz -C /tmp/ && \
    mv /tmp/picoclaw /usr/local/bin/picoclaw && \
    chmod +x /usr/local/bin/picoclaw && \
    rm -rf /tmp/picoclaw.tar.gz /tmp/picoclaw_*

# Download and install Tectonic (lightweight LaTeX compiler)
RUN wget -q https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.15.0/tectonic-0.15.0-x86_64-unknown-linux-gnu.tar.gz -O /tmp/tectonic.tar.gz && \
    tar -xzf /tmp/tectonic.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/tectonic && \
    rm -rf /tmp/tectonic.tar.gz

# Create app directory
RUN mkdir -p /app

# Copy entrypoint script and AGENTS.md
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
COPY AGENTS.md /app/AGENTS.md

# Set working directory
WORKDIR /app

# Expose port
EXPOSE 3000

# Start PicoClaw via entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
