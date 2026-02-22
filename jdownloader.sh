#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="antlafarge/jdownloader:dev-alpine-openjdk17"

CONTAINER_NAME="jdownloader-server"

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -z "$DATA_DIR" ]; then
  DATA_DIR="/sdcard/Download/JDownloader"
fi

yes | termux-setup-storage &>/dev/null

mkdir -p "$DATA_DIR"/{downloads,cfg,logs} || { echo "Need to grant storage permission"; exit 1; }

if [ -z "$JD_EMAIL" ]; then
  echo "Missing login email"
  exit 1
fi

if [ -z "$JD_PASSWORD" ]; then
  echo "Missing login password"
  exit 1
fi

if [ -z "$JAVA_OPTIONS" ]; then
  JAVA_OPTIONS="-Xms128m -Xmx1g"
fi

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "bash -c" -v "$DATA_DIR/downloads:/jdownloader/downloads" -v "$DATA_DIR/cfg:/jdownloader/cfg" -v "$DATA_DIR/logs:/jdownloader/logs" -e JD_EMAIL="$JD_EMAIL" -e JD_PASSWORD="$JD_PASSWORD" -e JD_DEVICENAME="$JD_DEVICENAME" -e JAVA_OPTIONS="$JAVA_OPTIONS" "$CONTAINER_NAME" "$cmd"
else
  udocker_run -v "$DATA_DIR/downloads:/jdownloader/downloads" -v "$DATA_DIR/cfg:/jdownloader/cfg" -v "$DATA_DIR/logs:/jdownloader/logs" -e JD_EMAIL="$JD_EMAIL" -e JD_PASSWORD="$JD_PASSWORD" -e JD_DEVICENAME="$JD_DEVICENAME" -e JAVA_OPTIONS="$JAVA_OPTIONS" "$CONTAINER_NAME"
fi

exit $?
