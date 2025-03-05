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
#### Video
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
  
* Check code to run perpetual video loops (```--f``` makes it play fullscreen, ```--loop=inf``` makes it loop forever, --geometry=100%x100% makes sure the video plays fullscreen on a pi monitor)
  
  ```console
  mpv --fs --geometry=100%x100% --loop=inf home/pi/Videos/test.mp4
  ```

#### Adding some fun
For enhanced anthropomorphic fun (oh yeah, and maybe some debugging), we can develop a launch script that first says something and then plays opens the full screen video. We're going to do this with ```espeak```:

```console
sudo apt-get install espeak
```
Next we're going to integrate everything in a python script that uses the module ```subprocess.call``` to execute shell comands.

Create a python script (e.g. ```sudo nano videoplayer.py```) and add the following python code:

```python
#! /usr/bin/env python
import subprocess
import time

# Wait until the GUI taskbar (lxpanel) is running
while True:
    try:
        output = subprocess.check_output("pgrep lxpanel", shell=True)
        if output.strip():  # If we get a valid PID, the GUI is ready
            break
    except subprocess.CalledProcessError:
        time.sleep(2)  # Wait and retry

# Speak the welcome message
subprocess.call(["espeak", "This is Industrial Design Engineering. Be amazed, be inspired, change the world."], stderr=subprocess.DEVNULL)

# Play the movie in full screen
subprocess.call(["mpv", "--fs", "--geometry=100%x100%", "--loop=inf", "/home/pi/Videos/drone.mp4"])
```


#### Booting
If you have a Raspi dedicated to looping that video (in this case: the pi is automatically powered down and powered up at the end and beginning of each day). This is how you create a custom boot that directly opens the mpv player and runs the video in a loop:  
* [good resource](https://www.dexterindustries.com/howto/run-a-program-on-your-raspberry-pi-at-startup/)

There are several options to do this:
* ```rc.local```: low level, simple, for lightwait startup scripts without GUI (deprecated). Works good in headless mode (without a screen). The pi runs this script at boot, before all other services.
* ```.bashrc```: runs after login, starts only if a terminal session starts
* ```init.d```: well documented, Unix classic, good for background processes
* ```Systemd```: go to method in most cases. advanced error logging and allows GUI targetting
* ```Contab```: simple, good for lightweight tasks and recurring tasks (sheduling)

In this project, we will use systemd to launch the videoplayer at boot and crontab to shutdown before the power gets turned off.



* Create a new ```systemd``` service file:
  ()
  ```console
  sudo nano /etc/systemd/system/videoplayer.service
  ```

* Add the following code
 (change Restart=always to Restart=no if you want to work on the prototype)
  ```
  [Unit]
  Description=Autostart Video Player
  After=graphical.target
  Wants=graphical.target
  
  [Service]
  User=pi
  Group=pi
  Environment=DISPLAY=:0
  Type=idle
  ExecStart=/usr/bin/python3 /home/pi/videoplayer.py
  WorkingDirectory=/home/pi
  StandardOutput=journal
  StandardError=journal
  Restart=always
  RestartSec=5
  
  [Install]
  WantedBy=graphical.target
  ```
  
* enable this service:
  
  ```console
  sudo systemctl daemon-reload
  sudo systemctl enable videoplayer.service
  ```

* start this service to test it:
  
  ```console
  sudo systemctl start videoplayer.service
  ```

* to stop the service:
  ```console
  sudo systemctl disable videoplayer.service
  ```

* To monitor the logs
  ```console
  journalctl -u videoplayer.service --no-pager --reverse | less
  ```
  > status
  ```console
  sudo systemctl status videoplayer.service
  ```

#### Power management
You might want to set-up a cleaner way to shutdown and restart the pi, since just powering it down might damage the SD card over time.
* Option 1: add a shutdown script that shuts the pi down before the power is cut (check [crontabguru](https://crontab.guru/) for set-up)
  
  ```console
  sudo crontab -e
  ```

  ```
  0 23 * * * sudo shutdown -h now
  ```

* Option 2: use a power management HAT such as the [Pimeroni OnOff SHIM](https://shop.pimoroni.com/products/onoff-shim?variant=41102600138)
