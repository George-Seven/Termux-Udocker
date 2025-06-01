#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="httpd"

CONTAINER_NAME="httpd-server"

case $PORT in
    ''|*[!0-9]*) PORT=2082;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=2082;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "$PORT:80" "$CONTAINER_NAME" "$cmd"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:80" -e _PORT="$PORT"  "$CONTAINER_NAME" ' \
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters\nff02::3     ip6-allhosts" >/etc/hosts; \
      sed -i -E "s/^Listen .*/Listen $_PORT/" /usr/local/apache2/conf/httpd.conf &>/dev/null; \
      mkdir -p /var/log/httpd; \
      rm -f /var/log/httpd/*.log; \
      touch /var/log/httpd/daemon.log; \
      tail -F /var/log/httpd/daemon.log & \
      _PIDFILE="$(mktemp)"; \
      start-stop-daemon -mp "$_PIDFILE" -bSa "$(command -v bash)" -- -c "exec $(command -v httpd-foreground) >/var/log/httpd/daemon.log 2>&1" && \
      while start-stop-daemon -Tp "$_PIDFILE"; do sleep 10; done
  '
fi

exit $?
