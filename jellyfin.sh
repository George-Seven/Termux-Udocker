#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE_NAME="jellyfin/jellyfin"

CONTAINER_NAME="jellyfin-server"

case $PORT in
    ''|*[!0-9]*) PORT=8096;;
    *) [ $PORT -gt 1023 ] && [ $PORT -lt 65536 ] || PORT=8096;;
esac

udocker_check

udocker_prune

udocker_create "$CONTAINER_NAME" "$IMAGE_NAME"

DATA_DIR="$(pwd)/data-$CONTAINER_NAME"

mkdir -p "$DATA_DIR"/{config,cache}

rm -rf /sdcard/.test_has_read_write_media

MEDIA_DIR_CONFIG=""

if ! touch /sdcard/.test_has_read_write_media &>/dev/null; then
    yes | termux-setup-storage &>/dev/null
    sleep 5
fi

if touch /sdcard/.test_has_read_write_media &>/dev/null; then
    mkdir -p /sdcard/{Download,DCIM,Movies,Music}
    MEDIA_DIR_CONFIG="-v /sdcard/Download -v /sdcard/DCIM -v /sdcard/Movies -v /sdcard/Music"
    echo "Mounting the following media directories -"
    echo "  /sdcard/Download"
    echo "  /sdcard/DCIM"
    echo "  /sdcard/Movies"
    echo "  /sdcard/Music"
fi

rm -rf /sdcard/.test_has_read_write_media

if [ -n "$1" ]; then
  unset cmd
  cmd="$*"
  udocker_run --entrypoint "bash -c" -p "$PORT:8096" -e DOTNET_GCHeapHardLimit="1C0000000" -v "$(proot_write_tmp "$(cat "$(pwd)/libnetstub.sh")"):/.libnetstub/libnetstub.sh" -v "$DATA_DIR/config:/config" -v "$DATA_DIR/cache:/cache" $MEDIA_DIR_CONFIG "$CONTAINER_NAME" ". /.libnetstub/libnetstub.sh; $cmd"
else
  udocker_run --entrypoint "bash -c" -p "$PORT:8096" -e _PORT="$PORT" -e DOTNET_GCHeapHardLimit="1C0000000" -v "$(proot_write_tmp "$(cat "$(pwd)/libnetstub.sh")"):/.libnetstub/libnetstub.sh" -v "$DATA_DIR/config:/config" -v "$DATA_DIR/cache:/cache" $MEDIA_DIR_CONFIG "$CONTAINER_NAME" ' \
      echo -e "127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost ip6-localhost ip6-loopback\nfe00::0     ip6-localnet\nff00::0     ip6-mcastprefix\nff02::1     ip6-allnodes\nff02::2     ip6-allrouters\nff02::3     ip6-allhosts" >/etc/hosts; \
      if [[ ! -f /.libnetstub/libnetstub.so && -f /.libnetstub/libnetstub.sh ]]; then \
          export DEBIAN_FRONTEND=noninteractive && \
          apt update && \
          apt install -y dialog apt-utils && \
          apt install -y --no-install-recommends gcc libc6-dev && \
          mkdir -p /.libnetstub && \
          echo ". /.libnetstub/libnetstub.sh" | tee -a ~/.bashrc ~/.zshrc >/dev/null; \
          . /.libnetstub/libnetstub.sh; \
          apt remove -y gcc libc6-dev && apt autoremove -y && apt clean -y && apt autoclean -y; \
      fi; \
      . /.libnetstub/libnetstub.sh; \
      mkdir -p /config/config; \
      if [[ ! -f /config/config/network.xml ]]; then \
          echo -e "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<NetworkConfiguration xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n  <BaseUrl />\n  <EnableHttps>false</EnableHttps>\n  <RequireHttps>false</RequireHttps>\n  <CertificatePath />\n  <CertificatePassword />\n  <InternalHttpPort>8096</InternalHttpPort>\n  <InternalHttpsPort>8920</InternalHttpsPort>\n  <PublicHttpPort>8096</PublicHttpPort>\n  <PublicHttpsPort>8920</PublicHttpsPort>\n  <AutoDiscovery>true</AutoDiscovery>\n  <EnableUPnP>false</EnableUPnP>\n  <EnableIPv4>true</EnableIPv4>\n  <EnableIPv6>false</EnableIPv6>\n  <EnableRemoteAccess>true</EnableRemoteAccess>\n  <LocalNetworkSubnets />\n  <LocalNetworkAddresses />\n  <KnownProxies />\n  <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>\n  <VirtualInterfaceNames>\n    <string>veth</string>\n  </VirtualInterfaceNames>\n  <EnablePublishedServerUriByRequest>false</EnablePublishedServerUriByRequest>\n  <PublishedServerUriBySubnet />\n  <RemoteIPFilter />\n  <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>\n</NetworkConfiguration>" >/config/config/network.xml; \
      fi; \
      command -v xmlstarlet &>/dev/null || { apt update && apt install -y --no-install-recommends xmlstarlet; }; \
      xmlstarlet ed --inplace -u "//InternalHttpPort" -v "$_PORT" -u "//PublicHttpPort" -v "$_PORT" /config/config/network.xml &>/dev/null; \
      exec /jellyfin/jellyfin --nonetchange
  '
fi

exit $?
