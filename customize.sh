SKIPUNZIP=1
    version=$(grep_prop version $TMPDIR/module.prop | awk -F " " '{print $1}')
    ui_print "****************"
    ui_print " SmartDNS - Android"
    ui_print " $version"
    ui_print " pymumu (module by x4455)"
    ui_print "****************"

    [ $API -ge 28 ] && { ui_print '(!) Please close the Private DNS to prevent conflict.'; }

    ui_print "- Extracting module files"
    unzip -oj "$ZIPFILE" 'common/*' -x 'common/tools/*' -d $MODPATH >&2
    mkdir $MODPATH/tools
    unzip -oj "$ZIPFILE" 'common/tools/*' -d $MODPATH/tools >&2
    unzip -oj "$ZIPFILE" 'binary/*' -d $TMPDIR >&2

    case $ARCH in
    arm|arm64|x86|x64)
        BINARY_PATH=$TMPDIR/$MODID-$ARCH ;;
    *)
        abort "(E) $ARCH are unsupported architecture." ;;
    esac

    MODDIR=$MODPATH
    oldver=`grep -E '^version=' $NVBASE/modules/$MODID/module.prop | awk -F '[()]' '{print $2}'`
    . $MODDIR/lib.sh
    touch $MODPATH/skip_mount

    if [ -f "$BINARY_PATH" -a -f $TMPDIR/setuidgid ]; then
        chmod 0755 $BINARY_PATH
        ver=$($BINARY_PATH -v | awk -F " " '{print $2}')
        ui_print "- Version: [$ver]"
        sed -i -e "s/<VER>/${ver}/" $TMPDIR/module.prop
        cp $TMPDIR/module.prop $MODPATH

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
    elif [ "$oldver" != "$ver" ]; then
        unzip -oj "$ZIPFILE" 'config/smartdns.conf' -d $TMPDIR >&2
        cp -af $TMPDIR/smartdns.conf $DATA_INTERNAL_DIR/example-smartdns.conf
    fi

    ui_print "- Setting permissions"
    set_perm_recursive $MODPATH 0 0 0755 0644
    set_perm_recursive $CORE_INTERNAL_DIR 0 2000 0755 0755
    for FILE in $(find $MODPATH -maxdepth 2 -type f -name *".sh"); do
        set_perm $FILE 0 2000 0755
    done

inherit() {
    local tmp=$(grep "^$1=" $MODDIR/lib.sh)
    if [ "${2}" != 'bool' ]; then
        sed -i "s#^$tmp#$1=\'$2\'#g" $MODDIR/lib.sh
    else
        if [ "${3}" == 'true' -o "${3}" == 'false' ]; then
            sed -i "s#^$tmp#$1=$3#g" $MODDIR/lib.sh
        fi
    fi
}

if $BOOTMODE; then
    . $NVBASE/modules/$MODID/lib.sh
    inherit Route_PORT $Route_PORT
    inherit Listen_PORT $Listen_PORT
    inherit Mode $Mode
    inherit ServerUID $ServerUID
    inherit IP6T_block bool $IP6T_block
    inherit VPN bool $VPN
    inherit Strict bool $Strict
fi