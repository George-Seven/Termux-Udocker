#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

IMAGE_NAME="nextcloud"

CONTAINER_NAME="nextcloud-server"

case $PORT in
    ''|*[!0-9]*) PORT=2080;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT="2080";;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  udocker_run --entrypoint "bash -c" -p "$PORT:80" "$CONTAINER_NAME" "$@"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:80" "$CONTAINER_NAME" '_PORT="'$PORT'"; sed -i -E "s/^Listen .*/Listen $_PORT/" /etc/apache2/ports.conf &>/dev/null; sed -i "s/<VirtualHost .*/<VirtualHost *:$_PORT>/" /etc/apache2/sites-enabled/000-default.conf &>/dev/null; mkdir -p /var/log/apache2; rm -f /var/log/apache2/*.{pid,log} /var/run/apache2/*.pid; touch /var/log/apache2/{access,error,other_vhosts_access,daemon}.log; tail -F /var/log/apache2/error.log 1>&2 & tail -qF /var/log/apache2/{access,other_vhosts_access,daemon}.log & _PIDFILE="$(mktemp)"; start-stop-daemon -mp "$_PIDFILE" -bSa "$(command -v bash)" -- -c "exec /entrypoint.sh apache2-foreground >/var/log/apache2/daemon.log 2>&1" && while start-stop-daemon -Tp "$_PIDFILE"; do sleep 10; done'
fi

exit $?
