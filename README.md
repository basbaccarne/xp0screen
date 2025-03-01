# XP0SCREEN   
This repo describes the set-up of an autonomous installation to play movies in a perpetual loop. Perfect for demo stands etc.   
### Components
- [ ] [Raspberri Pi](https://www.raspberrypi.com/products/) (optimal: Zero 2W or 3)
- [ ] [Micro SD Card](https://be.farnell.com/transcend/ts2gusdc/card-sd-micro-2gb/dp/2290242)
- [ ] [Raspberry Pi Monitor](https://be.farnell.com/raspberry-pi/sc0940/rpi-monitor-red-white/dp/4568688)
- [ ] USB-C cable
- [ ] [HDMI cable](https://be.farnell.com/raspberry-pi/t7689ax/cable-micro-hdmi-hdmi-plug-1m/dp/3107125)
- [ ] [Raspberry Pi power supply](https://be.farnell.com/multicomp-pro/mp004971/adapter-ac-dc-5-1v-3a/dp/3058875)
- [ ] [Timer Switch](https://be.farnell.com/brennenstuhl/mz-20/timer-24hour-mechanica-euro-plug/dp/7966466)

### Physical build   
* The Raspberry Pi is connected to the screen using UBC (screen power, use seperate power for higher brightness) and a HDMI cable
* The Raspberry Pi is powered over USB through a timer switch that auto shuts down and boots the pi each day
* The Raspberry Pi is attached to the screen using a 3D printed ```VESA``` mount (adapted from [ChooseCool](https://www.thingiverse.com/thing:3808242))

### Computational set-up   
The lowest level of video playing on raspi used to be [OMXplayer](https://github.com/popcornmix/omxplayer). Unfortunately the OMX team has shifted focus to developing VLC, so this version is new deprecated (doesn't work on bullseye or bookworm). Hence, it has become more difficult to run videos from the CLI only OS systems (Raspi Lite). Now , it is best to use [MPV](https://github.com/mpv-player/mpv).

* Install a fresh Raspi OS
* Update system
  
  ```console
  sudo apt update
  sudo apt upgrade -y
  ```
  
* Check MPV installation (want more public test videos > [gist](https://gist.github.com/jsturgis/3b19447b304616f18657))
  
  ```console
  sudo apt install mpv -y
  mpv http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4
  ```

* Add video files to the Pi (WinSCP or USB stick)
  
* Check code to run perpetual video loops (```--f``` makes it play fullscreen, ```--loop=inf``` makes it loop forever)
  
  ```console
  mpv --fs --loop=inf test.mp4
  ```

If you have a Raspi dedicated to looping that video (in this case: the pi is automatically powered down and powered up at the end and beginning of each day). This is how you create a custom boot that directly opens the mpv player and runs the video in a loop:  

* Create a service
  
  ```console
  sudo nano /etc/systemd/system/expo.service
  ```
  
* add the following content in the file:   
  (change Restart=always to Restart=no if you want to work on the prototype)

  ```
  [Unit]
  Description=Play Video on Boot
  After=graphical.target
  
  [Service]
  User=expo
  ExecStart=/usr/bin/mpv --fs --loop=inf /home/expo/test.mp4
  Restart=always
  Environment=DISPLAY=:0
  StandardInput=tty
  StandardOutput=tty
  
  [Install]
  WantedBy=multi-user.target
  ```

* enable this service:
  
  ```console
  sudo systemctl enable expo.service
  ```

* start this service:
  
  ```console
  sudo systemctl start expo.service
  ```

* If you want to restart the scrit:
  ```console
  sudo systemctl restart expo.service
  ```
* To monitor the logs
  > Live
  ```console
  journalctl -u expo.service -f
  ```
  > Last x minutes
  ```console
  sudo journalctl -u expo.service --since "5 minutes ago"
  ```
  > status
  ```console
  sudo systemctl status mpv-video.service
  ```

You might want to set-up a cleaner way to shutdown and restart the pi, since just powering it down might damage the SD card over time.
* Option 1: add a shutdown script that shuts the pi down before the power is cut (check [crontabguru](https://crontab.guru/) for set-up)
  
  ```console
  sudo crontab -e
  ```

  ```
  0 23 * * * sudo shutdown -h now
  ```

* Option 2: use a power management HAT such as the [Pimeroni OnOff SHIM](https://shop.pimoroni.com/products/onoff-shim?variant=41102600138)
