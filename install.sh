
##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you.
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

version=$(grep_prop version $TMPDIR/module.prop | awk -F " " '{print $1}')
print_modname() {
	ui_print "****************"
	ui_print " Smartdns - Android"
	ui_print " $version"
	ui_print " module by x4455"
	ui_print "****************"
}

on_install() {
  # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
  # Extend/change the logic to whatever you want
	ui_print "- Extracting module files"
	unzip -o "$ZIPFILE" 'system/*' 'core/*' -d $MODPATH >&2

	imageless_magisk || { abort '(!) Please update Magisk to 18.1+.'; }

	[ $API -ge 28 ] && {
	ui_print ""
	ui_print '(!) Please close the Private DNS to prevent conflict.'
	ui_print ""
	}

	# Install script
	case $ARCH in
	arm|arm64|x86|x64)
		BINARY_PATH=$TMPDIR/smartdns-$ARCH;;
	*)
		abort "(E) $ARCH are unsupported architecture."
	esac

	. $TMPDIR/lib.sh

	if [ -f "$BINARY_PATH" ]; then
		set_perm $BINARY_PATH 0 0 0755
		ver=$($BINARY_PATH -v | awk -F " " '{print $2}')
		ui_print "- Version: [$ver]"
		sed -i -e "s/<VER>/${ver}/" $TMPDIR/module.prop

		cp -af $BINARY_PATH $MODPATH/core/$CORE_BINARY
	else
		abort "(E) $ARCH binary file missing."
	fi

	if [ $(ls $DATA_INTERNAL_DIR | wc -l) -eq 0 ]; then
		ui_print ""
		ui_print '(!!!) 默认仅提供基础联网功能，需要您自行设置配置。'
		ui_print '(!!!) Requires you to set the configuration yourself,'
		ui_print ' only basic networking features are provided by default.'
		ui_print ""
		unzip -o "$ZIPFILE" 'config/*' -d $TMPDIR >&2
		mkdir -p $DATA_INTERNAL_DIR 2>/dev/null
		cp -rf $TMPDIR/config/* $DATA_INTERNAL_DIR
		sleep 5
	fi

	cp -af $TMPDIR/lib.sh $MODPATH/lib.sh
	cp -af $TMPDIR/script.sh $MODPATH/system/xbin/smartdns
}


set_permissions() {
  # The following is the default rule, DO NOT remove
	set_perm_recursive $MODPATH 0 0 0755 0644
	set_perm_recursive $MODPATH/core 0 0 0755 0755
	set_perm_recursive $MODPATH/system 0 0 0755 0755

  # Here are some examples:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}
