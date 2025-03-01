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
* The Raspberry Pi is attached to the screen using a 3D printed VESA mount (adapted from [ChooseCool](https://www.thingiverse.com/thing:3808242))

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
