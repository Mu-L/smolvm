#!/usr/bin/env bash
# Persistent workload: a warm X desktop served over VNC on :5900. Kept running
# so the machine can be frozen as a fork base and cloned per episode.
set -e
export DISPLAY=:0
Xvfb :0 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 1.5
fluxbox >/tmp/fluxbox.log 2>&1 &
xterm -geometry 100x30+20+20 -e "echo smolvm VNC desktop; date; bash" >/tmp/xterm.log 2>&1 &
x11vnc -display :0 -forever -nopw -rfbport 5900 -shared -bg -o /tmp/x11vnc.log
echo "VNC desktop up on :5900"
tail -f /dev/null
