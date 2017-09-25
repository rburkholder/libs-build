# Libs-Build

Some of my projects have complicated dependencies. 

This script will automatically build the dependencies.

As of 2016/09/25, it works with the Trade-Frame project:

```
./build.sh tradeframe
```

This script requires bash, and is tested on:
* Debian Stretch x64
* Debian Buster x64

The library manager apt-get is used extensively.

* libraries are installed into /usr/local/lib 
* includes are placed in /usr/local/include
