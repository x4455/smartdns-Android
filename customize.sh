SKIPUNZIP=1
	ui_print "- module version: [ $(grep_prop version $TMPDIR/module.prop | awk -F " " '{print $1}') ]"

	# 只从管理器安装
	[ "$BOOTMODE" == 'true' ] || abort "[Error]: Please install from Magisk Manager."

	# 冲突判断
	[ "$API" -ge 28 -a $(settings get global private_dns_mode) != 'off' ] && {
		ui_print "****************"
		ui_print '(!) 请关闭私人DNS以防止冲突'
		ui_print '(!) Please close the Private DNS to prevent conflict.'
		ui_print "****************"
	}

	ui_print "- Extracting module files"

	# 控制脚本
	unzip -oj "$ZIPFILE" 'common/*' -d $MODPATH >&2
	# 语言文件
	unzip -o "$ZIPFILE" 'translations/*' -d $MODPATH >&2

	# 创建 /etc/resolv.conf
	etcPATH=$(realpath /etc)
	if echo $etcPATH |grep -q -e '^\/system' ; then
		mkdir -p $MODPATH$etcPATH
		echo -e 'nameserver 9.9.9.9\nnameserver 208.67.222.222' > $MODPATH$etcPATH/resolv.conf
	else
		ui_print "****************"
		ui_print '[错误]: 文件结构未适配，请联系作者寻求帮助。'
		ui_print '[Error]: The file structure is not adapted, Please contact the author for help.'
		ui_print "****************"
		abort "$(ls -l /etc)"
	fi

	# 为 constant.sh 提供路径
	readonly MODDIR=$MODPATH
	. $MODPATH/constant.sh
	# 已安装模块路径
	readonly installed_PATH=${MODPATH/modules_update/modules}

	# 创建调用
	mkdir -p $MODPATH/system/bin
	#ln -fs $installed_PATH/command.sh $MODPATH/system/bin/$CORE_NAME
	echo -e "#!/system/bin/sh\nexec $installed_PATH/command.sh \"\$@\"" > $MODPATH/system/bin/$CORE_NAME

	#####

	# binary 文件解压
	unzip -oj "$ZIPFILE" 'binary/*' -d $TMPDIR >&2
	# 证书库
	unzip -o "$TMPDIR/ca-certificates.zip" -d $MODPATH/binary >&2

	# 架构判断
	case $ARCH in
	arm|arm64)
		sleep 1
		;;
	*)
		abort "[Error]: $ARCH are unsupported architecture." ;;
	esac
	readonly BINARY_PATH=$TMPDIR/$ARCH


	#核心
	if [ -f "$BINARY_PATH" ]; then
		# 版本信息写入到模块信息
		chmod 0755 $BINARY_PATH
		coreVer=$($BINARY_PATH -v |awk -F ' ' '{print $2}')
		Ver=`grep_prop versionCode $TMPDIR/module.prop`
		ui_print "- Server: [ $coreVer ] Script: [ $Ver ]"
		sed -i -e "s/<VER>/${coreVer}/" $TMPDIR/module.prop
		cp $TMPDIR/module.prop $MODPATH
		# 安装程序
		cp $BINARY_PATH $CORE_INTERNAL_DIR/$CORE_NAME
	else
		abort "[Error]: $ARCH binary file missing."
	fi


	## 版本变化配置处理↓
	#配置文件
	unzip -o "$ZIPFILE" 'config/*' -d $TMPDIR >&2
	#其他脚本
	unzip -o "$ZIPFILE" 'scripts/*' -d $TMPDIR >&2
	if [ ! -d "$DATA_INTERNAL_DIR" ]; then
		# 若配置路径不存在
		ui_print "****************"
		ui_print '(!) 需要自行设置配置。'
		ui_print '(!) Requires you to set the configuration yourself.'
		ui_print "****************"
		# 创建配置
		mkdir -p $DATA_INTERNAL_DIR
		cp -a $TMPDIR/config/* $DATA_INTERNAL_DIR/
		mkdir -p $SCRIPT_INTERNAL_DIR
		cp -a $TMPDIR/scripts/* $SCRIPT_INTERNAL_DIR/
		# 创建脚本配置
		cp $MODPATH/defaults.sh $SCRIPT_CONF
	else
		ui_print "****************"
		ui_print '(!) 尝试继承模块设置。如果出错,请使用示例文件重新配置。'
		ui_print '(!) Try inheriting the module setting. If something goes wrong, reconfigure it.'
		ui_print "****************"
		# 配置更新
		if [ -f $DATA_INTERNAL_DIR/reset ]; then
			rm -r $DATA_INTERNAL_DIR
			mkdir -p $DATA_INTERNAL_DIR
			cp -a $TMPDIR/config/* $DATA_INTERNAL_DIR/
			cp $MODPATH/defaults.sh $SCRIPT_CONF
		else
			# 更新程序示例配置
			cp -f $TMPDIR/config/smartdns.conf $DATA_INTERNAL_DIR/example-smartdns.conf
			# 更新脚本示例配置
			cp -f $MODPATH/defaults.sh $DATA_INTERNAL_DIR/example-script_conf.sh
		fi
		# scripts 更新
		if [ -f $SCRIPT_INTERNAL_DIR/reset ]; then
			rm -r $SCRIPT_INTERNAL_DIR
			mkdir -p $SCRIPT_INTERNAL_DIR
			cp -rf $TMPDIR/scripts/* $SCRIPT_INTERNAL_DIR/
		fi
	fi

	ui_print '- Setting permissions'
	set_perm_recursive $MODPATH 0 0 0755 0644

	set_perm $MODPATH/command.sh 0 0 0755
	set_perm $MODPATH/system/bin/$CORE_NAME 0 0 0755

	set_perm $CORE_INTERNAL_DIR/setuidgid 0 0 0755
	set_perm $CORE_INTERNAL_DIR/$CORE_NAME 0 0 0755

	set_perm_recursive $DATA_INTERNAL_DIR 0 $(id -g radio) 0755 0644
	set_perm_recursive $SCRIPT_INTERNAL_DIR 0 0 0755 0644

	# for file in $(find $MODPATH -type f -maxdepth 1 -name '*.sh'); do
	# 	set_perm $file 0 0 0755
	# done
