#!/data/data/com.termux/files/usr/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/source.env"

install_udocker

fix_udocker

exit $?
