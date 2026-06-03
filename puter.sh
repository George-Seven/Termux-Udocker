#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="ghcr.io/heyputer/puter"

CONTAINER_NAME="puter-server"

case $PORT in
    ''|*[!0-9]*) PORT=4100;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=4100;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR"/{config,data}

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "sh -c" -p "$PORT:4100" -v "$DATA_DIR/config:/etc/puter" -v "$DATA_DIR/data:/var/puter" "$CONTAINER_NAME" "$cmd"
else
  udocker_run --entrypoint "sh -c" -p "$PORT:4100" -e _PORT="$PORT" -v "$DATA_DIR/config:/etc/puter" -v "$DATA_DIR/data:/var/puter" "$CONTAINER_NAME" ' \
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters\nff02::3     ip6-allhosts" >/etc/hosts; \
      command -v jq &>/dev/null || apk add --no-cache jq; \
      [ -f /etc/puter/config.json ] && ( cd "$(mktemp -d)"; jq ".http_port = \"$_PORT\"" /etc/puter/config.json > config.json; mv config.json /etc/puter/config.json; ); \
      exec npm start
  '
fi

exit $?
