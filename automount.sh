#!/bin/bash

set -e

bcachefs_mount() {
	LABEL="$1"
	MOUNTPOINT="$2"
	bcachefs unlock "/dev/disk/by-partlabel/$LABEL" < /mnt/keydisk/bcachefs_keyfile
	DEVICES="$(blkid -t PARTLABEL="$LABEL" -o device | tr '\n' ':' | sed -z '$ s/:$//')"
	mount -t bcachefs "$DEVICES" "$MOUNTPOINT"
}

bcachefs_mount bcachefs_backup /mnt/migratedrv
