#!/usr/bin/env bash
set -euo pipefail

DOCKER_DIR="$HOME/Astro-Hono-oRpc/docker"
PROJECT_DIR="$HOME/Astro-Hono-oRpc/project"
DIST_CLIENT="$PROJECT_DIR/dist/client"
STATIC_DIR="/var/www/astro-static"
IMAGE_NAME="astro-app:latest"
TEMP_CONTAINER="temp-astro-extract"

echo "🔨 Building Docker image..."
docker build \
  -t "$IMAGE_NAME" \
  -f "$DOCKER_DIR/astro/Dockerfile" \
  "$PROJECT_DIR"

echo "📦 Extracting dist/client from image..."
docker rm -f "$TEMP_CONTAINER" 2>/dev/null || true
docker create --name "$TEMP_CONTAINER" "$IMAGE_NAME"
rm -rf "$DIST_CLIENT"
docker cp "$TEMP_CONTAINER:/app/dist/client" "$DIST_CLIENT"
docker rm "$TEMP_CONTAINER"

echo "✅ dist/client extracted to $DIST_CLIENT"

echo "🗜️  Copying and pre-compressing static assets..."
rsync -a --delete "$DIST_CLIENT/" "$STATIC_DIR/"

# Only compress files that don't already have a compressed version
find "$STATIC_DIR" -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.svg" -o -name "*.json" \) \
  ! -name "*.gz" ! -name "*.br" | while read -r file; do
    [ -f "$file.gz" ] || gzip -9 -k "$file"
    [ -f "$file.br" ] || brotli -q 11 -k "$file"
done

echo "✅ Compression done"

echo "🔄 Starting/restarting containers..."
docker compose -f "$DOCKER_DIR/compose.yaml" up --remove-orphans

echo "🎉 Deploy complete!"
