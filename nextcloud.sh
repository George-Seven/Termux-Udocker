#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="nextcloud"

CONTAINER_NAME="nextcloud-server"

case $PORT in
    ''|*[!0-9]*) PORT=2080;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=2080;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR"/html

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "$PORT:80" -v "$DATA_DIR/html:/var/www/html" "$CONTAINER_NAME" "$cmd"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:80" -e _PORT="$PORT" -v "$DATA_DIR/html:/var/www/html" "$CONTAINER_NAME" ' \
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters\nff02::3     ip6-allhosts" >/etc/hosts; \
      sed -i -E "s/^Listen .*/Listen $_PORT/" /etc/apache2/ports.conf &>/dev/null; \
      sed -i "s/<VirtualHost .*/<VirtualHost *:$_PORT>/" /etc/apache2/sites-enabled/000-default.conf &>/dev/null; \
      mkdir -p /var/log/apache2; \
      rm -f /var/log/apache2/*.{pid,log} /var/run/apache2/*.pid; \
      touch /var/log/apache2/{access,error,other_vhosts_access,daemon}.log; \
      tail -F /var/log/apache2/error.log 1>&2 & \
      tail -qF /var/log/apache2/{access,other_vhosts_access,daemon}.log & \
      _PIDFILE="$(mktemp)"; \
      start-stop-daemon -mp "$_PIDFILE" -bSa "$(command -v bash)" -- -c "exec /entrypoint.sh apache2-foreground >/var/log/apache2/daemon.log 2>&1" && \
      while start-stop-daemon -Tp "$_PIDFILE"; do sleep 10; done
  '
fi

exit $?
