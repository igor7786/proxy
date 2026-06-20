#!/usr/bin/env bash

set -euo pipefail

echo "Stopping all running containers..."
containers=$(docker ps -aq)
if [ -n "$containers" ]; then
  docker stop $containers
else
  echo "No running containers."
fi

echo "Removing all containers..."
containers=$(docker ps -aq)
if [ -n "$containers" ]; then
  docker rm $containers
else
  echo "No containers to remove."
fi

echo "Removing all volumes..."
volumes=$(docker volume ls -q)
if [ -n "$volumes" ]; then
  docker volume rm $volumes
else
  echo "No volumes to remove."
fi

echo "Pruning system (images, cache, networks, etc.)..."
docker system prune -a --volumes -f

echo "Removing non-redpanda images..."
images=$(docker images --format '{{.ID}} {{.Repository}}' \
  | grep -v 'redpanda' \
  | awk '{print $1}')
if [ -n "$images" ]; then
  docker rmi -f $images
else
  echo "No images to remove."
fi

echo "Kept redpanda images:"
docker images | grep redpanda

echo "DONE ✔"
