# Description
Correctly configures Udocker so that it works properly in Termux.
<br>

#### What's Udocker?
It's a userspace implementation of Docker.

It means that it can, without root or custom-kernel, run Docker images and containers.

And it does this without spinning up an entire qemu-VM, which makes it much, much faster than any other alternatives.

https://f-droid.org/en/packages/com.termux/

https://github.com/indigo-dc/udocker

<br>

# Instructions
In Termux -

```
git clone --depth 1 https://github.com/George-Seven/Termux-Udocker ~/Termux-Udocker
```
```
bash ~/Termux-Udocker/install_udocker.sh
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

### Customize
#### Change Port
```
PORT=9080 ~/Termux-Udocker/s-pdf.sh
```

Add `PORT=number` before the script. Port must be from 1024~65535.

<br>

#### Run custom commands
```
~/Termux-Udocker/s-pdf.sh 'echo hello world; echo hi'
```

To override the default startup commands with your own, add your commands after the script like so.

<br>
