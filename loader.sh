#!/bin/sh
# This is Squash App /bin/sh version of bootloader
# In general bootloader is small bootstrap application designed 
# to be runable on target architecture with least effort on 
# the end user side.
# 
# Bootloader is tacked on in front of the FS image of squashed application,
# the PGP signature of bootloader (if present) is appended to the end of runnable
# .squash file, AFTER the signature of FS image.

# In order to call bootloader commands use the following sequence
# --squash-boot <command> [squash-bootloder command args]

# By default if the first argument is not --squash-boot then all of them
# are passed down as is to the squashed application image

# Bootloader commands:
# pad		outputs boot.sh, padded to exactly 4kb (useful after patching)
# split  	splits composed image file to <image-name>.boot.sh, <image-name>.fs, <image-name>.boot.sig, <image-name>.fs.sig
# combine 	combines <image-name>.squash> from <image-name>.boot.sh, <image-name>.boot.sh.sig, <image-name>.fs.sig
# fs 		show application's FS image contents instead of running
# run 		(default - runs the app)

# ============================================================================
BIN="$(readlink -f $0)"
NAME="$(basename $0)"

[ "$BIN" != "" ] || die "Cannot determine app name from command line: $0" 
if [ "$HOME" == "" ] ; then
	echo "HOME is undefined. Falling back to /tmp" >&2
	HOME=/tmp
fi

UNPACKED="$HOME/.squash-apps/$NAME"
CACHE="$HOME/.squash-apps/.cache"
mkdir -p "$UNPACKED"
mkdir -p "$CACHE"

ARCH=$(uname -m)
OS=$(uname -s | tr [A-Z] [a-z])
CMD=run

INIT="/bin/init.$OS.$ARCH"

if [ $# -gt 1 ] && [ "$1" == "--squash-boot" ]; then
	CMD="$2"
	shift 2
fi

populate_fs_cache() {
	IMAGE="$CACHE/$NAME"
	dd if="$BIN" bs=4k skip=1 of="/tmp/$NAME.squashfs" 2>/dev/null || die "failed to copy fs image"
	if ! diff "/tmp/$NAME.squashfs" "$IMAGE" > /dev/null 2>&1 ; then 
		mv "/tmp/$NAME.squashfs" "$IMAGE"
		unlink "$IMAGE.up-to-date" 2>/dev/null # remove up-to-date cache flag file
	else
		touch "$IMAGE.up-to-date" # set up-to-date flag file
	fi
}

case $CMD in 
	pad)
		TOTAL=4096
		SZ=$(stat -f "%z" "$BIN")
		PADDING=$(expr $TOTAL - $SZ)
		cat $BIN
		dd if=/dev/zero bs=1 count=$PADDING 2>/dev/null | tr '\0' '#'
	;;
	fs)
		populate_fs_cache
		unsquashfs -l "$IMAGE"
	;;
	run)
		populate_fs_cache
		if ! [ -f "$IMAGE.up-to-date" ] ; then
			cd "$UNPACKED"
			rm -rf * || die "failed to cleanup unpacked cache dir: $UNPACKED"
			echo "Unpacking SquashFS image" >&2
			unsquashfs -f "$IMAGE" | grep -v created && mv squashfs-root/* . && rmdir squashfs-root
		else
			TS=$(stat -f %m "$CACHE/$NAME")
			DATE=$(date -r $TS)
			echo "Running from cache (last modifed $DATE)" >&2 
		fi
		if [ "$OS" == "freebsd" ] ; then
			echo "TODO: SquashApp on FreeBSD, must run inside jail"	
			#TODO: setup jail with bind mounts and run /bin/init.freebsd.$arch
		fi
		# this is a fallback: running unpacked and without sandboxing
		cd "$UNPACKED"
                . etc/rc.conf
		export $(cut -d'=' -f1 etc/rc.conf)
		read shebang < "bin/init.$OS.$ARCH"
		CMD=$(echo "$shebang" | sed 's/#!//')
		echo "Running $INIT $squash_app_args"
		exec .$CMD .$INIT $squash_app_args

	;;
	*)
		echo "Unrecognized squash app bootloader command: '$CMD'">&2
	;;
esac


exit 0

# ============================================================================
# boot.sh PADDING STARTS HERE - the total size must be 4kb
# ============================================================================
