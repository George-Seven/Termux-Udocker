#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="quay.io/jupyter/base-notebook"

CONTAINER_NAME="jupyter-server"

case $PORT in
    ''|*[!0-9]*) PORT=8888;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=8888;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR"/jovyan

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "$PORT:8888" -e JUPYTER_PORT="$PORT" -v "$DATA_DIR/jovyan:/home/jovyan" "$CONTAINER_NAME" "$cmd"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:8888" -e JUPYTER_PORT="$PORT" -v "$DATA_DIR/jovyan:/home/jovyan" "$CONTAINER_NAME" ' \
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters\nff02::3     ip6-allhosts" >/etc/hosts; \
      exec tini -s -g -- start.sh start-notebook.py
  '
fi

exit $?
