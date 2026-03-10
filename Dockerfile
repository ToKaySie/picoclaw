FROM debian:bookworm-slim

# Install minimal dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates bash && \
    rm -rf /var/lib/apt/lists/*

# Download and install PicoClaw binary
RUN wget -q https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_Linux_x86_64.tar.gz -O /tmp/picoclaw.tar.gz && \
    tar -xzf /tmp/picoclaw.tar.gz -C /tmp/ && \
    mv /tmp/picoclaw /usr/local/bin/picoclaw && \
    chmod +x /usr/local/bin/picoclaw && \
    rm -rf /tmp/picoclaw.tar.gz /tmp/picoclaw_*

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
