#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="frooodle/s-pdf"

CONTAINER_NAME="stirling-pdf-server"

case $PORT in
    ''|*[!0-9]*) PORT=8080;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=8080;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR/"{trainingData,extraConfigs,customFiles,logs,pipeline}

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "$PORT:8080" -e LANGS="en_US" -v "$DATA_DIR/trainingData:/usr/share/tessdata" -v "$DATA_DIR/extraConfigs:/configs" -v "$DATA_DIR/customFiles:/customFiles" -v "$DATA_DIR/logs:/logs" -v "$DATA_DIR/pipeline:/pipeline" "$CONTAINER_NAME" "$cmd"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:8080" -e _PORT="$PORT" -e LANGS="en_US" -v "$DATA_DIR/trainingData:/usr/share/tessdata" -v "$DATA_DIR/extraConfigs:/configs" -v "$DATA_DIR/customFiles:/customFiles" -v "$DATA_DIR/logs:/logs" -v "$DATA_DIR/pipeline:/pipeline" "$CONTAINER_NAME" ' \
      apk add openjdk17-jre yq; \
      touch /configs/custom_settings.yml; \
      yq -i ".server.host = \"0.0.0.0\" | .server.port = $_PORT" /configs/custom_settings.yml; \
      ln -nsf /usr/lib/jvm/java-17-openjdk /usr/lib/jvm/default-jvm; \
      java -jar /app.jar
  '
fi
 
exit $?
