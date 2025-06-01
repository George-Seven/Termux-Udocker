#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="lscr.io/linuxserver/calibre-web"

CONTAINER_NAME="calibre-web-server"

case $PORT in
    ''|*[!0-9]*) PORT=8083;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=8083;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR"/{config,books}

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "$PORT:8083" -e CALIBRE_PORT="$PORT" -e TZ="$(get_tz)" -v "$DATA_DIR/config:/config" -v "$DATA_DIR/books:/books" "$CONTAINER_NAME" "$cmd"
else
  udocker_run --entrypoint "bash -c " -p "$PORT:8083" -e CALIBRE_PORT="$PORT" -e TZ="$(get_tz)" -v "$DATA_DIR/config:/config" -v "$DATA_DIR/books:/books" "$CONTAINER_NAME" ' \
      ln -nsf /defaults/policy.xml /etc/ImageMagick-6/policy.xml; \
      if [[ ! -f /config/client_secrets.json ]]; then echo "{}" > /config/client_secrets.json; fi; \
      if [[ -f /usr/bin/kepubify ]] && [[ ! -x /usr/bin/kepubify ]]; then chmod +x /usr/bin/kepubify; fi; \
      mkdir -p /app/calibre-web/cps/cache /config /books; \
      export CALIBRE_DBPATH=/config; \
      if [[ ! -f /config/app.db ]]; then \
          echo "First time run, creating app.db..."; \
          cd /app/calibre-web; \
          python3 /app/calibre-web/cps.py -d &>/dev/null; \
          echo "update settings set config_kepubifypath='\''/usr/bin/kepubify'\'' where config_kepubifypath is NULL or LENGTH(config_kepubifypath)=0;" | sqlite3 /config/app.db; \
          if [[ $? == 0 ]]; then \
              echo "Successfully set kepubify paths in /config/app.db"; \
          elif [[ $? > 0 ]]; then
              echo "Could not set binary paths for /config/app.db (see errors above)."; \
          fi; \
      fi; \
      if [[ ! -f /books/metadata.db ]]; then \
          curl -sL -o /books/metadata.db "https://github.com/janeczku/calibre-web/raw/refs/heads/master/library/metadata.db"; \
      fi; \
      ln -nsf /books/metadata.db /metadata.db; \
      exec python3 /app/calibre-web/cps.py -o /dev/stdout
  '
fi

exit $?
