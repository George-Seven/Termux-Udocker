# Description

Correctly configures Udocker so that it works properly in Termux.

**Update -** Thanks to [@IntinteDAO](https://github.com/termux/termux-packages/pull/24699), **udocker** is now officially available in the Termux APT Repo. I've updated the configs to use it.

<br>

#### What's Udocker?

It's a user-space implementation of Docker.

This means that it can, without root or custom-kernel, run Docker images and containers.

And it does this without spinning up an entire qemu-VM, which makes it much, much faster than any other alternatives.

https://f-droid.org/en/packages/com.termux/

https://github.com/indigo-dc/udocker

<br>

# Instructions

In Termux -

```
pkg i git -y && git clone --depth 1 https://github.com/George-Seven/Termux-Udocker ~/Termux-Udocker; git -C ~/Termux-Udocker pull; bash ~/Termux-Udocker/install_udocker.sh
```

And done.

#### Help text

```
udocker --help
```

#### Keep it updated

```
cd ~/Termux-Udocker; git pull
```

<br>

### Examples

Here are example scripts provided for some popular Docker images -

> [!NOTE]
> Popular Docker repos provide 64-bit images, but not all of them provide the older 32-bit images.
>
> Running `uname -m`, if it shows 64, then your phone is 64-bit. Which means it'll work for everything given below.
>
> You can still check if the repo supports 32-bit by checking the tag link next to the name.

<br>

#### Name: Stirling PDF ([frooodle/s-pdf:latest](https://hub.docker.com/r/frooodle/s-pdf/tags))

```
~/Termux-Udocker/s-pdf.sh
```

Connect to it at - [http://localhost:8080](http://localhost:8080)

<br>

#### Name: Home-Assistant ([homeassistant/home-assistant:latest](https://hub.docker.com/r/homeassistant/home-assistant/tags))

```
~/Termux-Udocker/home-assistant.sh
```

Connect to it at - [http://localhost:8123](http://localhost:8123)

<br>

#### Name: Jupyter ([quay.io/jupyter/base-notebook:latest](https://hub.docker.com/r/jupyter/base-notebook/tags))

```
~/Termux-Udocker/jupyter.sh
```

Connect to it at - [http://localhost:8888](http://localhost:8888)

<br>

#### Name: Nextcloud ([nextcloud:latest](https://hub.docker.com/_/nextcloud/tags))

```
~/Termux-Udocker/nextcloud.sh
```

Connect to it at - [http://localhost:2080](http://localhost:2080)

<br>

#### Name: ownCloud ([owncloud/server:latest](https://hub.docker.com/_/owncloud/tags))

```
~/Termux-Udocker/owncloud.sh
```

Connect to it at - [http://localhost:2081](http://localhost:2081)

<br>

#### Name: Calibre-Web ([lscr.io/linuxserver/calibre:latest](https://hub.docker.com/r/linuxserver/calibre-web/tags))

```
~/Termux-Udocker/calibre-web.sh
```

Connect to it at - [http://localhost:8031](http://localhost:8031)

> [!NOTE]
> Default Calibre-Web -  
> username: admin  
> password: admin123

<br>

#### Name: HTTPD ([httpd:latest](https://hub.docker.com/_/httpd/tags))

```
~/Termux-Udocker/httpd.sh
```

Connect to it at - [http://localhost:2082](http://localhost:2082)

<br>

#### Name: Redis ([redis:latest](https://hub.docker.com/_/redis/tags))

```
~/Termux-Udocker/redis.sh
```

Connect to it at - [http://localhost:6379](http://localhost:6379)

<br>

#### Name: Jellyfin ([jellyfin/jellyfin:latest](https://hub.docker.com/r/jellyfin/jellyfin/tags))

```
~/Termux-Udocker/jellyfin.sh
```

Connect to it at - [http://localhost:8096](http://localhost:8096)

<br>

#### Name: Puter ([ghcr.io/heyputer/puter:latest](https://github.com/heyputer/puter/pkgs/container/puter))

```
~/Termux-Udocker/puter.sh
```

Connect to it at - [http://puter.localhost:4100](http://puter.localhost:4100)

<br>

#### ROS - Robot Operating System ([ghcr.io/sloretz/ros:jazzy-ros-base](https://hub.docker.com/_/ros/tags))

```
~/Termux-Udocker/ros.sh
```

<br>

### Customize

#### Change Port

```
PORT=9080 ~/Termux-Udocker/s-pdf.sh
```

Add `PORT=number` before the script. Port must be from 1024~65535.

<br>

#### Run custom commands

To override the default startup commands, append your own commands after the script, like this -

```
~/Termux-Udocker/s-pdf.sh 'echo hello world; echo hi'
```

<br>

### Tips

#### List containers

```
udocker ps
```

#### Remove containers

```
udocker rm "container_name"
```

#### List images

```
udocker images
```

#### Remove images

```
udocker rmi "image_name"
```

<br>

