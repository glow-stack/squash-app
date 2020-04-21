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

echo "/bin/init.$OS.$ARCH" >&2

if [ $# -gt 1 ] && [ "$1" == "--squash-boot" ]; then
	CMD="$2"
	shift 2
fi

populate_fs_cache() {
	IMAGE="$CACHE/$NAME"
	if ! diff "$BIN" "$IMAGE" > /dev/null ; then
		dd if="$BIN" bs=4k skip=1 of="$IMAGE" 2>/dev/null || die "failed to copy fs image"
	fi
	touch $IMAGE.ready # create a flag file
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
		if ! [ -f "$IMAGE.ready" ] ; then
			cd "$UNPACKED"
			rm -rf * || die "failed to cleanup unpacked cache dir: $UNPACKED"
			echo "Unpacking FS image" >&2
			unsquashfs -f "$IMAGE" | grep -v created && mv squashfs-root/* . && rmdir squashfs-root
		else
			TS=$(stat -f %m "$CACHE/$NAME")
			DATE=$(date -r $TS)
			echo "Running from cache (last modifed $DATE)" >&2 
		fi
		if uname | grep "FreeBSD" > /dev/null ; then
			echo "SquashApp on FreeBSD: trying to sandbox inside of jail"	
		fi
		cd $DEST && exec "$DEST/bin/init"
	;;
	*)
		echo "Unrecognized squash app bootloader command: '$CMD'">&2
	;;
esac


exit 0

# ============================================================================
# boot.sh PADDING STARTS HERE - the total size must be 4kb
# ============================================================================
