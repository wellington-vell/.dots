#!/usr/bin/env bash
# Ensure the motherboard sound card uses the analog profile and is the
# default sink (PipeWire/WirePlumber). Run once per Hyprland session start.

set -u

CARD=$(wpctl status | awk '/PRIME B450M-A Motherboard/ && /\[alsa\]/ { for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.$/) { sub(/\./,"",$i); print $i; exit } }')
[ -n "$CARD" ] && wpctl set-profile "$CARD" 1 >/dev/null 2>&1

for _ in $(seq 1 50); do
  SINK=$(wpctl status | awk '/Analog Stereo/ && /PRIME B450M-A Motherboard/ { for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.$/) { sub(/\./,"",$i); print $i; exit } }')
  if [ -n "$SINK" ]; then
    wpctl set-default "$SINK" >/dev/null 2>&1
    exit 0
  fi
  sleep 0.2
done

exit 1