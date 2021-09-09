#!/bin/bash

set -e

BCACHE_DEVICES="$(lsblk --fs --list --json | jq -r '.blockdevices[] | select(.fstype == "bcache") | .name')"

bcachefs_uuid() {
	DEV="$1"
	bcachefs show-super "$DEV" | grep -F 'External UUID' | cut -d: -f2 | tr -d '\r\n\t '
}

bcachefs_mount() {
	UUID="$1"
	MOUNTPOINT="$2"
	KEYFILE="$3"

	DEVICE=""
	DEVICES=""
	for dev in $BCACHE_DEVICES
	do
		dev="/dev/$dev"
		if [ "$(bcachefs_uuid "$dev")" == "$UUID" ]
		then
			DEVICE="$dev"
			DEVICES="$DEVICES$dev:"
		fi
	done

	DEVICES="$(echo -n "$DEVICES" | sed -z '$ s/:$//')"

	if [ ! -z "$KEYFILE" ]
	then
		bcachefs unlock "$DEVICE" < "$KEYFILE"
	fi
	mount -t bcachefs "$DEVICES" "$MOUNTPOINT"
}

