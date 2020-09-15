SKIPUNZIP=1
	version=$(grep_prop version $TMPDIR/module.prop | awk -F " " '{print $1}')
	ui_print "****************"
	ui_print " SmartDNS - Android"
	ui_print " $version"
	ui_print " pymumu (module by x4455)"
	ui_print "****************"

	[ $API -ge 28 ] && { ui_print '(!) Please close the Private DNS to prevent conflict.'; }

	#架构
	case $ARCH in
	arm|arm64|x86|x64)
		BINARY_PATH=$TMPDIR/$MODID-$ARCH ;;
	*)
		abort "[Error]: $ARCH are unsupported architecture." ;;
	esac

	ui_print "- Extracting module files"

	#核心
	unzip -oj "$ZIPFILE" 'binary/*' -x 'binary/ca-certificates.zip' -d $TMPDIR >&2
	#证书库
	unzip -o "$ZIPFILE" 'binary/*' -x 'binary/smartdns-*' -d $MODPATH >&2
	unzip -o "$MODPATH/binary/ca-certificates.zip" -d $MODPATH/binary >&2
	rm $MODPATH/binary/ca-certificates.zip

	#工具
	unzip -oj "$ZIPFILE" 'common/*' -d $MODPATH >&2
	unzip -o "$ZIPFILE" 'tools/*' -x 'tools/placeholder' -d $MODPATH >&2

	#创建/etc/resolv.conf
	etcPATH=$(ls -l /etc |awk -F ' -> ' '{print $2}')
	mkdir -p $MODPATH$etcPATH
	echo -e 'domain lan\nnameserver 8.8.8.8\nnameserver 9.9.9.9' > $MODPATH$etcPATH/resolv.conf
	#touch $MODPATH/skip_mount

	#为lib提供路径转换
	MODDIR=$MODPATH
	#获取旧版本
	oldPATH=${MODPATH/modules_update/modules}
	[ -f $oldPATH/module.prop ] && \
	 { oldver=`grep -E '^version=' $oldPATH/module.prop |awk -F '[()]' '{print $2}'`; }||{ oldver=''; }
	. $MODDIR/lib.sh

	#版本信息 写入module
	if [ -f "$BINARY_PATH" ]; then
		chmod 0755 $BINARY_PATH
		ver=$($BINARY_PATH -v |awk -F ' ' '{print $2}')
		ui_print "- Server version: [$ver]"
		sed -i -e "s/<VER>/${ver}/" $TMPDIR/module.prop
		cp $TMPDIR/module.prop $MODPATH
		cp $BINARY_PATH $CORE_INTERNAL_DIR/$CORE_BINARY
	else
		abort "[Error]: $ARCH binary file missing."
	fi

	#配置文件
	# 若配置路径已存在，则版本更新后释放示例文件
	if [ ! -d $DATA_INTERNAL_DIR ]; then
		ui_print ''
		ui_print '(!!!) Requires you to set the configuration yourself.'
		ui_print '(!!!) 需要您自行设置配置。'
		ui_print ''
		mkdir -p $DATA_INTERNAL_DIR
		unzip -o "$ZIPFILE" 'config/*' -d $TMPDIR >&2
		cp $TMPDIR/config/* $DATA_INTERNAL_DIR/
		sleep 5
	elif [ "$oldver" != "$ver" ]; then
		unzip -oj "$ZIPFILE" 'config/smartdns.conf' -d $TMPDIR >&2
		cp $TMPDIR/smartdns.conf $DATA_INTERNAL_DIR/example-smartdns.conf
	fi

	ui_print '- Setting permissions'
	set_perm_recursive $MODPATH 0 0 0755 0644
	set_perm_recursive $CORE_INTERNAL_DIR 0 0 0755 0755
	set_perm_recursive $CORE_INTERNAL_DIR/CA 0 0 0755 0644
	set_perm_recursive $DATA_INTERNAL_DIR 0 0 0777 0664
	for file in $(find $MODPATH -maxdepth 2 -type f -name *'.sh'); do
		set_perm $file 0 2000 0750
	done

	#继承参数
inherit() {
	local tmp=$(grep "^$1=" $MODPATH/lib.sh)
	if [ "${2}" != 'bool' ]; then
		sed -i "s#^$tmp#$1=\'$2\'#g" $MODPATH/lib.sh
	else
		if [ "${3}" == 'true' -o "${3}" == 'false' ]; then
			sed -i "s#^$tmp#$1=$3#g" $MODPATH/lib.sh
		fi
	fi
}

	# Recovery mode cannot inherit settings
if [ "$BOOTMODE" == 'true' -a -f $oldPATH/lib.sh ]; then
	ui_print '- Try to inherit settings'
	ui_print '(!!!) Unexpected errors can occur.'
	. $oldPATH/lib.sh || exit 0
	inherit Route_PORT "$Route_PORT"
	inherit Listen_PORT "$Listen_PORT"
	inherit mode "$mode"
	inherit ServerUID "$ServerUID"
	inherit IP6T_block bool "$IP6T_block"
	inherit vpn bool "$vpn"
	inherit pkg "$pkg"
	inherit strict bool "$strict"
	inherit tools "$tools"
fi