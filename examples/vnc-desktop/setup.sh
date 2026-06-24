#!/usr/bin/env bash
# init: install a minimal X + VNC desktop stack into the image.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq xvfb x11vnc fluxbox xterm >/dev/null
echo "desktop packages installed"
