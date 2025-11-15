#!/data/data/.com.termux/files/usr/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/source.env"
cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="corentinth/papra:latest-rootless"
# https://github.com/papra-hq/papra/releases - corentinth/papra:25.10.X-rootles
# Change container name, to test new release
CONTAINER_NAME="papra-latest"

case $PORT in
	''|*[!0-9]*) PORT=1221;;
	*) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=1221;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR/documents"
mkdir -p "$DATA_DIR/db"

udocker_run \
  -e APP_BASE_URL="http://$(ip address show wlan0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1):1221" \
  -p 1221:1221 \
  -v "$DATA_DIR/db:/app/app-data/db" \
  -v "$DATA_DIR/documents:/app/app-data/documents" \
  $CONTAINER_NAME

