FROM oven/bun:1 AS base
WORKDIR /app

COPY package.json bun.lock ./

# =========================
# Production dependencies
# =========================
FROM base AS prod-deps

ENV NODE_ENV=production

RUN bun install --frozen-lockfile --production --ignore-scripts

# =========================
# Build dependencies
# =========================
FROM base AS build-deps

RUN bun install --frozen-lockfile

# =========================
# Build app
# =========================
FROM build-deps AS build

COPY . .

RUN bun run build

# =========================
# Runtime image
# =========================
FROM oven/bun:1-slim AS runtime


WORKDIR /app

RUN groupadd -r -g 1500 appgroup && \
    useradd -r -u 1500 -g appgroup appuser

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=4321
ENV SQLITE_PATH=/app/data/sqlite/sqlite.db


# Ensure the mount target exists and is owned by appuser before
# the volume gets mounted over it — otherwise Docker may create
# the mount point as root and appuser can't write to it.
RUN mkdir -p /app/data/sqlite && chown -R appuser:appgroup /app/data/sqlite
# # Copy app files with correct ownership
COPY --chown=appuser:appgroup --from=prod-deps /app/node_modules ./node_modules

COPY --chown=appuser:appgroup --from=build /app/dist ./dist

COPY --chown=appuser:appgroup --from=build /app/public ./public

COPY --chown=appuser:appgroup package.json ./

COPY --chown=appuser:appgroup --from=build /app/data/og-fallback ./data/og-fallback

# Switch to non-root user
USER appuser

EXPOSE 4321

CMD ["bun", "run", "--bun", "./dist/server/entry.mjs"]
