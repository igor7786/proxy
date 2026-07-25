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
ENV NODE_ENV=production

COPY . .

RUN bun run build

# =========================
# Runtime image
# =========================
FROM oven/bun:1-slim AS runtime
ENV NODE_ENV=production
WORKDIR /app



RUN groupadd -r -g 1500 appgroup && \
    useradd -r -u 1500 -g appgroup appuser

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=4321


# Ensure the mount target and fallback folders exist with correct ownership
RUN mkdir -p /app/data/sqlite ./data/og-fallback && \
    chown -R appuser:appgroup /app/data/sqlite ./data/og-fallback

# Copy app files with correct ownership
COPY --chown=appuser:appgroup --from=prod-deps /app/node_modules ./node_modules
COPY --chown=appuser:appgroup --from=build /app/dist ./dist
COPY --chown=appuser:appgroup --from=build /app/public ./public
COPY --chown=appuser:appgroup package.json ./

# 🌟 FIX 1: Copy tsconfig.json so Bun knows how to resolve the `@/` alias
COPY --chown=appuser:appgroup tsconfig.json ./

# 🌟 FIX 2: Copy the ENTIRE src directory so Bun can find your drizzle client/schema files
COPY --chown=appuser:appgroup --from=build /app/src/lib/drizzle/sqlite/db ./src/lib/drizzle/sqlite/db
# COPY --chown=appuser:appgroup --from=build /app/src/lib/drizzle/sqlite/manifest.json ./src/lib/drizzle/sqlite/manifest.json
COPY --chown=appuser:appgroup --from=build /app/src/lib/drizzle/sqlite ./src/lib/drizzle/sqlite

COPY --chown=appuser:appgroup --from=build /app/src/lib/env/server.env.ts ./src/lib/env/server.env.ts

# 🚨 ADD THIS: Copy the src directory containing your script
COPY --chown=appuser:appgroup --from=build /app/src/scripts ./scripts

# Switch to non-root user
USER appuser

EXPOSE 4321

CMD ["sh", "-c", "bun ./scripts/manifest.sqlite.ts && bun run --bun ./dist/server/entry.mjs"]
