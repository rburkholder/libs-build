# Libs-Build

Some of my projects have complicated dependencies. 

This script will automatically build the dependencies.

As of 2021/09/25, CERN's ROOT Data Analysis Framework works with the Trade-Frame project:

```
./build.sh tradeframe
./build.sh rdaf
```

* rdaf is Cern's ROOT Data Analysis Framework.  Note that it does take a while to download & build.  It is used for projects in the trade-frame/rdaf subdirectory.

NOTE: 2022/06/22 manually edit to change wxwidgets from 3.1.7 to 3.0.5 to match requirements of trade-frame.  3.1.7 is used with a private repository at this point.

This script requires bash, and is tested on:
* Debian Bullseye x64
* Debian Bookworm x64

The library manager apt-get is used extensively.

* libraries are installed into /usr/local/lib 
* includes are placed in /usr/local/include

This script needs to be run as a non-root user, and does call sudo in several places.  
When running this in a container, ensure that sudo has been installed:

```
apt install sudo
```

Test using sudo.  If you encounter an error like:

```
sudo: no tty present and no askpass program specified
```

A file created with mode 0440 in /etc/sudoers.d/myuser with following content is needed:

```
myuser ALL=(ALL) NOPASSWD: ALL
```

More info at https://stackoverflow.com/questions/21659637/how-to-fix-sudo-no-tty-present-and-no-askpass-program-specified-error

NOTE: there is '-march=native' in some builds, so the code is not necessarily compatible between CPUs of different types

