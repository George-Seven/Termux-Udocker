#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

IMAGE_NAME="httpd"

CONTAINER_NAME="httpd-server"

case $PORT in
    ''|*[!0-9]*) PORT=2082;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT="2082";;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  udocker_run --entrypoint "bash -c" -p "$PORT:80" "$CONTAINER_NAME" "$@"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:80" "$CONTAINER_NAME" '_PORT="'$PORT'"; sed -i -E "s/^Listen .*/Listen $_PORT/" /usr/local/apache2/conf/httpd.conf &>/dev/null; mkdir -p /var/log/httpd; rm -f /var/log/httpd/*.log; touch /var/log/httpd/daemon.log; tail -F /var/log/httpd/daemon.log & _PIDFILE="$(mktemp)"; start-stop-daemon -mp "$_PIDFILE" -bSa "$(command -v bash)" -- -c "exec $(command -v httpd-foreground) >/var/log/httpd/daemon.log 2>&1" && while start-stop-daemon -Tp "$_PIDFILE"; do sleep 10; done'
fi

exit $?
