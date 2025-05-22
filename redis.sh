#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

IMAGE_NAME="redis"

CONTAINER_NAME="redis-server"

case $PORT in
    ''|*[!0-9]*) PORT=6379;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT="6379";;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR"

if [ -n "$1" ]; then
  udocker_run --entrypoint "bash -c" -p "$PORT:6379" "$CONTAINER_NAME" "$@"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:6379" -e _PORT="$PORT"  -v "$DATA_DIR:/data" "$CONTAINER_NAME" ' \
      redis-server --port "$_PORT"
  '
fi

exit $?
