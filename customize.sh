SKIPUNZIP=1
	version=$(grep_prop version $TMPDIR/module.prop | awk -F " " '{print $1}')
	ui_print "****************"
	ui_print " SmartDNS - Android"
	ui_print " $version"
	ui_print " pymumu (module by x4455)"
	ui_print "****************"

	[ $MAGISK_VER_CODE -gt 18100 ] || { 
	ui_print "*******************************"
	ui_print " Please install Magisk v19.0+! "
	abort "*******************************"; }
	[ $API -ge 28 ] && { ui_print '(!) Please close the Private DNS to prevent conflict.'; }

	ui_print "- Extracting module files"
	unzip -oj "$ZIPFILE" 'common/*' -d $MODPATH >&2
	unzip -oj "$ZIPFILE" 'binary/*' -d $TMPDIR >&2

	case $ARCH in
	arm|arm64|x86|x64)
		BINARY_PATH=$TMPDIR/$MODID-$ARCH ;;
	*)
		abort "(E) $ARCH are unsupported architecture." ;;
	esac

	MODDIR=$MODPATH
	. $MODDIR/lib.sh

	if [ -f "$BINARY_PATH" -a -f $TMPDIR/setuidgid ]; then
		chmod 0755 $BINARY_PATH
		ver=$($BINARY_PATH -v | awk -F " " '{print $2}')
		ui_print "- Version: [$ver]"
		sed -i -e "s/<VER>/${ver}/" $TMPDIR/module.prop

		mkdir $CORE_INTERNAL_DIR
		cp $BINARY_PATH $CORE_INTERNAL_DIR/$CORE_BINARY
		cp $TMPDIR/setuidgid $CORE_INTERNAL_DIR
	else
		abort "(E) $ARCH binary file missing."
	fi

	if [ $(ls $DATA_INTERNAL_DIR | wc -l) -eq 0 ]; then
		ui_print ""
		ui_print '(!!!) Requires you to set the configuration yourself,'
		ui_print ' only basic networking features are provided by default.'
		ui_print '(!!!) 默认仅提供基础联网功能，需要您自行设置配置。'
		ui_print ""
		mkdir -p $DATA_INTERNAL_DIR
		unzip -oj "$ZIPFILE" 'config/*' -d $DATA_INTERNAL_DIR >&2
		sleep 5
	else
		unzip -oj "$ZIPFILE" 'config/smartdns.conf' -d $TMPDIR >&2
		cp -af $TMPDIR/smartdns.conf $DATA_INTERNAL_DIR/example-smartdns.conf
	fi

	cp $TMPDIR/module.prop $MODPATH
	touch $MODPATH/skip_mount

	ui_print "- Setting permissions"
	set_perm_recursive $MODPATH 0 0 0755 0644
	set_perm_recursive $CORE_INTERNAL_DIR 0 0 0755 0755
	set_perm $MODPATH/script.sh 0 2000 0755
	set_perm $MODPATH/lib.sh 0 2000 0755