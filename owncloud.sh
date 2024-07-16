#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

IMAGE_NAME="owncloud/server"

CONTAINER_NAME="owncloud-server"

case $PORT in
    ''|*[!0-9]*) PORT=2081;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT="2081";;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  udocker_run --entrypoint "bash -c" -p "$PORT:8080" "$CONTAINER_NAME" "$@"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:8080" -e APACHE_LISTEN="$PORT" "$CONTAINER_NAME" '_PORT="'$PORT'"; for i in $(find /etc/entrypoint.d -type f -name "*\.sh"); do sed -i -E '\''s#(_ERROR_?LOG.*)/dev/stderr#\1/var/log/apache2/error.log#g'\'' "$i"; sed -i -E '\''s#(_ACCESS_?LOG.*)/dev/stdout#\1/var/log/apache2/access.log#g'\'' "$i"; done; if ! [ -e /usr/bin/setpriv. ]; then mv -f /usr/bin/setpriv /usr/bin/setpriv.; echo -n "#!" > /usr/bin/setpriv; echo -en "/usr/bin/sh\n/usr/bin/setpriv. \"\$@\" 2>/dev/null >/dev/null | true" >> /usr/bin/setpriv; chmod 755 /usr/bin/setpriv; fi; mkdir -p /var/log/apache2; rm -f /var/log/apache2/*.{pid,log} /var/run/apache2/*.pid; touch /var/log/apache2/{access,error,other_vhosts_access,daemon}.log; tail -F /var/log/apache2/error.log 1>&2 & tail -qF /var/log/apache2/{access,other_vhosts_access,daemon}.log & _PIDFILE="$(mktemp)"; start-stop-daemon -mp "$_PIDFILE" -bSa "$(command -v bash)" -- -c "exec $(command -v entrypoint) $(command -v owncloud) server >/var/log/apache2/daemon.log 2>&1" && while start-stop-daemon -Tp "$_PIDFILE"; do sleep 10; done'
fi

exit $?
