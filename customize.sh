SKIPUNZIP=1
	version=$(grep_prop version $TMPDIR/module.prop | awk -F " " '{print $1}')
	ui_print "****************"
	ui_print " Smartdns - Android"
	ui_print " $version"
	ui_print " pymumu (module by x4455)"
	ui_print "****************"

ui_print "- Extracting module files"

unzip -oj "$ZIPFILE" module.prop 'common/*' -d $TMPDIR >&2
unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
cp -af $TMPDIR/post-fs-data.sh $MODPATH
cp -af $TMPDIR/service.sh $MODPATH
cp -af $TMPDIR/uninstall.sh $MODPATH
	cp -af $TMPDIR/lib.sh $MODPATH
	cp -af $TMPDIR/configs_update.sh $MODPATH
	cp -af $TMPDIR/script.sh $MODPATH/system/xbin/smartdns

	[ $MAGISK_VER_CODE -gt 18100 ] || \
	{ 
	ui_print "*******************************"
	ui_print " Please install Magisk v19.0+! "
	abort "*******************************"
	}

	[ $API -ge 28 ] && { ui_print '(!) Please close the Private DNS to prevent conflict.'; }

	# Install script
	case $ARCH in
	arm|arm64|x86|x64)
		BINARY_PATH=$TMPDIR/server-$ARCH ;;
	*)
		abort "(E) $ARCH are unsupported architecture." ;;
	esac

	MODDIR=$MODPATH
	. $TMPDIR/lib.sh

	if [ -f "$BINARY_PATH" -a -f $TMPDIR/setuidgid ]; then
		set_perm $BINARY_PATH 0 0 0755
		ver=$($BINARY_PATH -v | awk -F " " '{print $2}')
		ui_print "- Version: [$ver]"
		sed -i -e "s/<VER>/${ver}/" $TMPDIR/module.prop

		mkdir $CORE_INTERNAL_DIR
		cp -af $BINARY_PATH $CORE_INTERNAL_DIR/$CORE_BINARY
		cp -af $TMPDIR/setuidgid $CORE_INTERNAL_DIR
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
		mkdir -p $DATA_INTERNAL_DIR
		cp -rf $TMPDIR/config/* $DATA_INTERNAL_DIR
		sleep 5
	fi

	cp -af $TMPDIR/module.prop $MODPATH

ui_print "- Setting permissions"

	set_perm_recursive $MODPATH 0 0 0755 0644
	set_perm_recursive $CORE_INTERNAL_DIR 0 0 0755 0755
	set_perm_recursive $MODPATH/system 0 0 0755 0755