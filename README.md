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
pkg i git -y && git clone --depth 1 https://github.com/George-Seven/Termux-Udocker ~/Termux-Udocker; bash ~/Termux-Udocker/install_udocker.sh
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

#### Name: Stirling PDF (frooodle/s-pdf:latest)

```
~/Termux-Udocker/s-pdf.sh
```

Connect to it at - [http://localhost:8080](http://localhost:8080)

<br>

#### Name: Home-Assistant (homeassistant/home-assistant)

```
~/Termux-Udocker/home-assistant.sh
```

Connect to it at - [http://localhost:8123](http://localhost:8123)

<br>

#### Name: Nextcloud (nextcloud:latest)

```
~/Termux-Udocker/nextcloud.sh
```

Connect to it at - [http://localhost:2080](http://localhost:2080)

<br>

#### Name: ownCloud (owncloud/server:latest)

```
~/Termux-Udocker/owncloud.sh
```

Connect to it at - [http://localhost:2081](http://localhost:2081)

<br>

#### Name: Calibre-Web (lscr.io/linuxserver/calibre)

```
~/Termux-Udocker/calibre-web.sh
```

Connect to it at - [http://localhost:8031](http://localhost:8031)

> [!NOTE]
> Default Calibre-Web -  
> username: admin  
> password: admin123

<br>

#### Name: HTTPD (httpd:latest)

```
~/Termux-Udocker/httpd.sh
```

Connect to it at - [http://localhost:2082](http://localhost:2082)

<br>

#### Name: Redis (redis:latest)

```
~/Termux-Udocker/redis.sh
```

Connect to it at - [http://localhost:6379](http://localhost:6379)

<br>

#### ROS - Robot Operating System (ghcr.io/sloretz/ros:jazzy-ros-base)

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

