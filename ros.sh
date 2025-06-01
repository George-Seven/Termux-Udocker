#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="ghcr.io/sloretz/ros:jazzy-ros-base"

CONTAINER_NAME="ros-base"

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run -v "$(proot_write_tmp "$(cat "$(pwd)/libnetstub.sh")"):/.libnetstub/libnetstub.sh" "$CONTAINER_NAME" bash -c ". /.libnetstub/libnetstub.sh; $cmd"
else
  udocker_run --entrypoint "bash -c" -v "$(proot_write_tmp "$(cat "$(pwd)/libnetstub.sh")"):/.libnetstub/libnetstub.sh" "$CONTAINER_NAME" ' \
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters\nff02::3     ip6-allhosts" >/etc/hosts; \
      if [[ ! -f /.libnetstub/libnetstub.so && -f /.libnetstub/libnetstub.sh ]]; then \
          mkdir -p /.libnetstub; \
          echo ". /.libnetstub/libnetstub.sh" | tee -a ~/.bashrc ~/.zshrc >/dev/null; \
          . /.libnetstub/libnetstub.sh; \
      fi; \
       . /.libnetstub/libnetstub.sh; \
      exec /ros_entrypoint.sh bash
  '
fi

exit $?
