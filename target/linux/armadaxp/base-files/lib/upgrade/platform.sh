#
# Copyright (C) 2011 OpenWrt.org
#

. /lib/functions.sh

get_update_kernel_label() {
	cur_boot_part=`/usr/sbin/fw_printenv -n boot_part`
	kernel_label=""
	if [ "$cur_boot_part" -eq 1 ]
	then
		# current primary boot - update alt boot
		kernel_label="alt_kernel"
		fw_setenv boot_part 2
		fw_setenv bootcmd "run altnandboot" 
	elif [ "$cur_boot_part" -eq 2 ]
	then
		# current alt boot - update primary boot 
		kernel_label="kernel"
		fw_setenv boot_part 1
		fw_setenv bootcmd "run nandboot" 
	else
		# try to guess from bootarg, should not come here
		grep -q "mtdblock5" /proc/cmdline && next_boot_part=2 \
			&& kernel_label="alt_kernel" && next_bootcmd="run altnandboot"
		grep -q "mtdblock7" /proc/cmdline && next_boot_part=1 \
			&& kernel_label="kernel" && next_bootcmd="run nandboot"
		fw_setenv boot_part $next_boot_part
		fw_setenv bootcmd $next_bootcmd
	fi
	echo "$kernel_label"
}

platform_do_upgrade () {
	local kern_label=$(get_update_kernel_label)

	if [ ! -n "$kern_label" ]
	then
		echo "cannot find kernel partition"
		exit 1
	fi
	echo "Mamba do upgrade on $kern_label"
	get_image "$1" | mtd write - $kern_label 
}

platform_check_image() {
	# return 0 on valid image, 1 otherwise
	echo "Mamba check image"
	return 0
}

mamba_preupgrade() {
	echo "Mamba preupgrade called..."
	# populate the backup configuration files to overlay ubifs
	if [ -f "$CONF_TAR" -a "$SAVE_CONFIG" -eq 1 ]
	then
		rm -rf /overlay/openwrt_overlay/*
		tar -C /overlay/openwrt_overlay -x${TAR_V}zf "$CONF_TAR"
	else
		# do not keep config files
		rm -rf /overlay/openwrt_overlay/*
	fi
}

append sysupgrade_pre_upgrade mamba_preupgrade
