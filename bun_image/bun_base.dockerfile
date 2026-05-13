FROM oven/bun:1

WORKDIR /app


# Useful system packages
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*


RUN useradd -m bunuser \
    && chown -R bunuser:bunuser /app
# Optional defaults
ENV NODE_ENV=production

# Optional non-root user
RUN useradd -m bunuser
USER bunuser
