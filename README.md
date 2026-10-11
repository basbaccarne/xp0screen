# XP0SCREEN

An autonomous installation that plays a movie in a perpetual loop. Perfect for demo stands and the like.

**Contents:** [Components](#components) · [Physical build](#physical-build) · [Set-up](#set-up) · [Change the movie](#change-the-movie) · [Background](#background)

---

## Components

| Component | Note |
|-----------|------|
| [Raspberry Pi](https://www.raspberrypi.com/products/) | Zero 2W or 3 is enough for video; Pi 4+ can power the screen |
| [Micro SD card](https://be.farnell.com/transcend/ts2gusdc/card-sd-micro-2gb/dp/2290242) | |
| [Raspberry Pi Monitor](https://be.farnell.com/raspberry-pi/sc0940/rpi-monitor-red-white/dp/4568688) | There is also a black variant |
| [Raspberry Pi power supply](https://be.farnell.com/multicomp-pro/mp004971/adapter-ac-dc-5-1v-3a/dp/3058875) | |
| [USB-C charger](https://be.farnell.com/multicomp-pro/mc000992/usb-cable-3-1-type-a-type-c-plug/dp/2498938?MER=sy-me-pd-mi-alte) | Separate power for the screen: the Pi's USB power can fail if the screen draws from it. A Pi 5 also fails with the default keyboard |
| [HDMI cable](https://be.farnell.com/raspberry-pi/t7689ax/cable-micro-hdmi-hdmi-plug-1m/dp/3107125) | |
| [Micro HDMI adapter](https://be.farnell.com/startech/hdadfm5in/adapter-hdmi-to-micro-hdmi-5in/dp/3764999) | |
| [Timer switch](https://be.farnell.com/brennenstuhl/mz-20/timer-24hour-mechanica-euro-plug/dp/7966466) | Cuts and restores the power each day |
| [Short M2.5 bolts](https://be.farnell.com/tr-fastenings/m2-56krstmcz100/pozi-csk-head-machine-screw-steel/dp/2770703) | |
| [M2.5 x 12 bolts](https://be.farnell.com/tr-fastenings/m2-512krstmcz100/pozi-csk-head-machine-screw-steel/dp/2770705) | |
| [M2.5 x 11 standoffs](https://be.farnell.com/ettinger/05-02-113/spacer-m2-5x11-ni/dp/1466760) | |
| [M4 x 30 bolts](https://be.farnell.com/multicomp-pro/mp006530/screw-flat-csk-head-pozidriv-m4/dp/3666723) | Pi VESA goes 10 mm deep + 15 mm spacer + 6 mm brace thickness |
| [M5 x 35 bolt, nut & washer](https://be.farnell.com/multicomp-pro/mp014356/bolt-hex-head-m5-x-35-pvdf/dp/4550762) | |

## Physical build

- The Pi is connected to the screen (use separate power for higher brightness and more stability).
- The Pi is powered through a timer switch that cuts and restores the power each day.
- The Pi is attached to the screen with a 3D printed VESA [mount](https://a360.co/4igQT9M) (adapted from [ChooseCool](https://www.thingiverse.com/thing:3808242)).

## Set-up

**1. Install a fresh Raspberry Pi OS** (with desktop) and update it:

> The videoplayer requires the desktop version of Raspberry Pi OS. On Lite there is no desktop session, so the service would wait forever for it and never start the video.

```console
sudo apt update && sudo apt upgrade -y
```

**2. Copy your video** to the Pi as `~/Desktop/video.mp4` (WinSCP, USB stick, or `scp` from your computer):

```console
scp /path/to/your/video.mp4 pi@IP_ADDRESS:/home/pi/Desktop/video.mp4
```
> [!NOTE]
Get the pi IP with `ifconfig`

**3. Clone this repo and run the auto configuration:**

```console
git clone https://github.com/basbaccarne/xp0screen
cd xp0screen
sudo ./autoconfig.sh 18:00
```

> [!NOTE]
The optional argument is the time of the daily clean shutdown (default `18:00`). Set the timer switch to cut the power at least 10 minutes later, and to restore it in the morning.

**4. Reboot** with `sudo reboot`. The video starts by itself.

`autoconfig.sh` installs `mpv` and `espeak`, creates `~/videoplayer.py` and the `videoplayer.service` systemd service, disables screen blanking and schedules the daily shutdown. It is safe to run more than once.

## Change the movie

1. Attach a keyboard & mouse and press `CTRL+C`.
2. Open a terminal and stop the service:

   ```console
   sudo systemctl stop videoplayer.service
   ```

   > Do not use `disable`: the video would no longer start on boot.

3. Replace `~/Desktop/video.mp4`.
4. Start the service again:

   ```console
   sudo systemctl start videoplayer.service
   ```

5. Check that autostart is still on. This should print `enabled`:

   ```console
   systemctl is-enabled videoplayer.service
   ```

   If not: `sudo systemctl enable videoplayer.service`.

---

# Background

**Contents:** [Video player](#video-player) · [Launch script](#launch-script) · [Boot options](#boot-options) · [Systemd service](#systemd-service) · [Power management](#power-management) · [Disabling screen sleep](#disabling-screen-sleep)

## Video player

The lowest level of video playing on the Pi used to be [OMXplayer](https://github.com/popcornmix/omxplayer). It is deprecated (it doesn't work on bullseye or bookworm), which makes playing video from CLI-only systems (Raspberry Pi OS Lite) harder. Now it is best to use [MPV](https://github.com/mpv-player/mpv). More public test videos: [gist](https://gist.github.com/jsturgis/3b19447b304616f18657).

Test mpv manually:

```console
mpv http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4
```

The loop command used by the installation:

```console
mpv --fs --geometry=100%x100% --loop=inf /home/pi/Desktop/video.mp4
```

| Flag | Effect |
|------|--------|
| `--fs` | play fullscreen |
| `--loop=inf` | loop forever |
| `--geometry=100%x100%` | fill a Pi monitor |

## Launch script

For some anthropomorphic fun (and maybe some debugging), `videoplayer.py` first says something with `espeak` and then opens the fullscreen video with `subprocess.call`. `autoconfig.sh` generates it; edit the message there.

- `espeak -a 10` sets the speech volume.
- `mpv --volume=20` matches a speech volume of 10.

## Boot options

There are several ways to run something at boot ([good resource](https://www.dexterindustries.com/howto/run-a-program-on-your-raspberry-pi-at-startup/)):

| Method | Notes |
|--------|-------|
| `rc.local` | Low level, simple, for lightweight startup scripts without GUI (deprecated) |
| `.bashrc` | Runs after login, only if a terminal session starts |
| `init.d` | Well documented Unix classic, good for background processes |
| `systemd` | The go-to method in most cases; advanced error logging and allows GUI targeting |
| `crontab` | Simple, good for lightweight and recurring tasks (scheduling) |

This project uses **systemd** to launch the video player at boot and **cron** to shut down before the power gets cut.

## Systemd service

The unit is `/etc/systemd/system/videoplayer.service`. Set `Restart=no` in it if you want to work on the prototype.

- `ExecStartPre` waits for the desktop session, since the service can start before it exists at boot. The user id in the socket path (`1000`) is the default for user `pi` (check with `id -u`).
- Do not set `WAYLAND_DISPLAY`: it makes mpv use its Wayland backend, which blanks the screen and freezes the video on the Pi.
- In a unit file `%` must be written as `%%` (e.g. `--geometry=100%%x100%%`).

| Task | Command |
|------|---------|
| Stop until next boot | `sudo systemctl stop videoplayer.service` |
| Remove autostart for good | `sudo systemctl disable videoplayer.service` |
| Status | `sudo systemctl status videoplayer.service` |
| Logs | `journalctl -u videoplayer.service --no-pager --reverse \| less` |

## Power management

Just cutting the power to the Pi corrupts the SD card over time (symptoms: the Pi still gets an IP and answers ping, but ssh is refused and the video service doesn't start). The installation therefore powers itself down first, and only afterwards the timer switch cuts the power:

| Time | What happens |
|------|--------------|
| 18:00 | cron shuts the Pi down cleanly (`shutdown -h now`) |
| 18:15 | the timer switch cuts the power (the Pi has been off for a while) |
| 08:00 | the timer switch restores the power, the Pi boots and `videoplayer.service` starts the video |

### Option 1: cron

`autoconfig.sh` sets this up in root's crontab (so no password is needed). To change the time, run `sudo crontab -e` (see [crontabguru](https://crontab.guru/)):

```
0 18 * * * /usr/sbin/shutdown -h now
```

- Adapt the times to your opening hours.
- Check the Pi clock with `date`. Set the timezone with `sudo raspi-config` > Localisation Options > Timezone, otherwise the shutdown runs at the wrong time.
- To test without waiting: `sudo shutdown -h +1` (cancel with `sudo shutdown -c`), and check that the Pi stays off until you cut and restore the power.

### Option 2: power management HAT

Use a HAT such as the [Pimoroni OnOff SHIM](https://shop.pimoroni.com/products/onoff-shim?variant=41102600138).

## Disabling screen sleep

If the screen runs for a long time, auto sleep might blank it. `autoconfig.sh` adds `consoleblank=0` to `/boot/firmware/cmdline.txt`. To do it by hand, append it to the end of that single line.
