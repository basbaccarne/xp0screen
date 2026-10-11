#!/bin/bash
# Auto-configures a Raspberry Pi as a perpetual video looper (see README.md).
# Usage: sudo ./autoconfig.sh [shutdown-time HH:MM, default 18:00]
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo ./autoconfig.sh" >&2
  exit 1
fi

# The user that will play the video (the user who called sudo, default: pi)
PLAYER_USER="${SUDO_USER:-pi}"
[ "$PLAYER_USER" = "root" ] && PLAYER_USER="pi"
id "$PLAYER_USER" >/dev/null 2>&1 || { echo "User '$PLAYER_USER' does not exist" >&2; exit 1; }
PLAYER_UID="$(id -u "$PLAYER_USER")"
PLAYER_GROUP="$(id -gn "$PLAYER_USER")"
PLAYER_HOME="$(getent passwd "$PLAYER_USER" | cut -d: -f6)"

VIDEO="$PLAYER_HOME/Desktop/video.mp4"
SCRIPT="$PLAYER_HOME/videoplayer.py"
SERVICE=/etc/systemd/system/videoplayer.service
LOG="$PLAYER_HOME/Desktop/videoplayer.log"

SHUTDOWN_TIME="${1:-18:00}"
[[ "$SHUTDOWN_TIME" =~ ^([01]?[0-9]|2[0-3]):([0-5][0-9])$ ]] || { echo "Invalid time '$SHUTDOWN_TIME' (use HH:MM)" >&2; exit 1; }
SHUTDOWN_HOUR=$((10#${BASH_REMATCH[1]}))
SHUTDOWN_MIN=$((10#${BASH_REMATCH[2]}))

# How the shutdown time is spoken, e.g. "18 hours" or "18 hours 30"
SPOKEN_TIME="$SHUTDOWN_HOUR hours"
[ "$SHUTDOWN_MIN" -ne 0 ] && SPOKEN_TIME="$SPOKEN_TIME $SHUTDOWN_MIN"

echo "==> Installing packages (mpv, espeak)"
apt-get update
apt-get install -y mpv espeak

echo "==> Writing $SCRIPT"
mkdir -p "$PLAYER_HOME/Desktop"
chown "$PLAYER_USER:$PLAYER_GROUP" "$PLAYER_HOME/Desktop"
cat > "$SCRIPT" <<PYEOF
#! /usr/bin/env python3
import subprocess

# Speak the welcome message (-a sets volume of the text to speech on 10)
subprocess.call(["espeak", "-a", "10", "Video player is live. This system will automatically shut down at $SPOKEN_TIME."], stderr=subprocess.DEVNULL)

# Play the movie in full screen (volume of 20 seems to match text to speech volume of 10)
subprocess.call(["mpv", "--fs", "--geometry=100%x100%", "--loop=inf", "--volume=20", "$VIDEO"])
PYEOF
chown "$PLAYER_USER:$PLAYER_GROUP" "$SCRIPT"
chmod 755 "$SCRIPT"

echo "==> Writing $SERVICE"
cat > "$SERVICE" <<UNITEOF
[Unit]
Description=Autostart Video Player
After=graphical.target
Wants=graphical.target

[Service]
User=$PLAYER_USER
Group=$PLAYER_GROUP
Environment=DISPLAY=:0
Type=idle
# Wait until the desktop is up, otherwise mpv starts too early at boot and nothing is shown
ExecStartPre=/bin/sh -c 'until [ -S /run/user/$PLAYER_UID/wayland-0 ] || [ -S /tmp/.X11-unix/X0 ]; do sleep 1; done'
ExecStart=/usr/bin/python3 $SCRIPT
WorkingDirectory=$PLAYER_HOME
StandardOutput=file:$LOG
StandardError=file:$LOG
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
UNITEOF

echo "==> Enabling videoplayer.service"
systemctl daemon-reload
systemctl enable videoplayer.service
if [ -f "$VIDEO" ]; then
  systemctl restart videoplayer.service
  echo "    service started"
else
  echo "    $VIDEO not found: copy your video there, then run: sudo systemctl start videoplayer.service"
fi

echo "==> Disabling screen blanking"
CMDLINE=/boot/firmware/cmdline.txt
[ -f "$CMDLINE" ] || CMDLINE=/boot/cmdline.txt
if [ -f "$CMDLINE" ]; then
  if grep -q 'consoleblank=0' "$CMDLINE"; then
    echo "    already set"
  else
    sed -i '1 s/[[:space:]]*$/ consoleblank=0/' "$CMDLINE"
    echo "    added consoleblank=0 to $CMDLINE"
  fi
else
  echo "    cmdline.txt not found, skipped"
fi

echo "==> Scheduling daily clean shutdown at $(printf '%02d:%02d' "$SHUTDOWN_HOUR" "$SHUTDOWN_MIN")"
CRON_LINE="$SHUTDOWN_MIN $SHUTDOWN_HOUR * * * /usr/sbin/shutdown -h now"
{ crontab -l 2>/dev/null | grep -vF '/usr/sbin/shutdown -h now' || true; echo "$CRON_LINE"; } | crontab -
echo "    set the timer switch to cut power at least 10 minutes later"

echo
echo "Done. Reboot to test: sudo reboot"
