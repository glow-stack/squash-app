# Squash App

## A simple and compact application image tool


### Why?

I believe we (the IT lot) made way too many incompatible ways to package software,
and there is a whole industry built around its packaging and repackaging.

What should have been a mundane task, dealt with once and for good is a steaming
mess of competing projects with increasingly byzantine architectures.

The goal of Squash App is to show that:

1. We already had all of the required tools to neatly package software before containers, snap, flatpak, etc. were a thing.
2. One app - one (fast to mount/decompress & run) file and a signature for it. All you need is 1 or 2 files.
3. Simple file formats existing in the wild for over a decade is a win for end user (squashfs image format, gpg signature).
4. One compressed file - a multitude of platforms (OS and virutal or real hardware architectures) to run on. 
A single squashfs can easily represent "fat binary" by using a portable loader shell script as /bin/init.

### How?

The ingredients:
- [squashfs](https://github.com/plougher/squashfs-tools) - a compressed filesystem
- [gpg](https://www.gnupg.org/) - a tool to easily encrypt and sign/verify files
- [squash](./squash) - a simple portable `/bin/sh` script to run, verify, sign and (re)pack squashfs images of apps, depends on the former 2 tools
- any web server or network fileshare to serve the signed squashfs files to the end user
- any of your usual file system and command-line tools

### Synopsis
```shell
./squash pack examples/hello
... # (shows packing progress or asks for squashfs-tools to be installed)

./squash run examples/hello.squash.app

... # caches the image in $HOME/.squash-apps and unpacks to run the app, ultimately displaying "Hello, world"

# as a short-cut run command may be omited
./squash examples/hello.squash.app

... # since it's 2nd time should display "Running from cache (last modified <date-time>)" to stderr and runs the same Hello, world sample

```

### Future work

A brief TODO list

- more examples and how-tos for established languages and build tools
- outline how to build multi-platform and multi-arch images
- squash should provide simple sign/verify/keygen helper "commands" forwarding to gpg, of course
- squash script should easily be able to export/import squashfs app image from/to `.tar` compatible with OCI and runnable as container with runc and friends
- run in a unikernel-style by tacking on a suitable bootloader+kernel combo
- run as true unikernel on KVM/Xen/etc., by utilizing some of ideas of [unikraft](http://www.unikraft.org) and related projects
- try to find even more simple and efficient ways to run it removing excessive moving parts or supporting more targets with single image file

