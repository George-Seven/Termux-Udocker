#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

IMAGE_NAME="frooodle/s-pdf"

CONTAINER_NAME="stirling-pdf-server"

case $PORT in
    ''|*[!0-9]*) PORT=8080;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT="8080";;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  udocker_run --entrypoint "bash -c" -p "$PORT:8080" "$CONTAINER_NAME" "$@"
else
  udocker_run -p "$PORT:8080" "$CONTAINER_NAME" bash -c '_PORT="'$PORT'"; mkdir -p configs && echo -e "server:\n  host: 0.0.0.0\n  port: $_PORT" > configs/custom_settings.yml; apk add openjdk17-jre; ln -nsf /usr/lib/jvm/java-17-openjdk /usr/lib/jvm/default-jvm; java -Dfile.encoding=UTF-8 -jar /app.jar'
fi
 
exit $?
