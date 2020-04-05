#!/system/bin/sh
### Make sure to stop the server
### before modifying the parameters
# Main listen port
Listen_PORT='6053'
# Route listen port
Route_PORT='6553'

# Service Mode
#  local: Proxy local only
#  proxy: Proxy local and External query
#  server: Expecting the server only
Mode='local'

# Redirect VPN query
VPN=false

# Block IPv6 port 53 [true/false] or Redirect query
IP6T_block=true

# Limit queries from non-LAN
Strict=true

# Server permission [radio/root] (Some operations may want to use root)
ServerUID='radio'

####################
# Don't modify it. # Don't modify it. # Don't modify it.
# PATHs
IPT="/system/bin/iptables"
IP6T="/system/bin/ip6tables"

ROOT="/dev/smartdns"

CORE_INTERNAL_DIR="$MODDIR/binary"
DATA_INTERNAL_DIR="/data/media/0/Android/smartdns"

CORE_DIR="$ROOT/binary"
DATA_DIR="$ROOT/config"

CORE_BINARY="smartdns-server"
CORE_BOOT="$CORE_DIR/$CORE_BINARY -c $DATA_DIR/smartdns.conf -p $ROOT/server.pid"

################
# Lib functions
#set -x
server_start() {
    killall -s 9 $CORE_BINARY >/dev/null 2>&1
    # setuidgid [UID GID GROUPS]
    $CORE_DIR/setuidgid $(id -u $ServerUID) $(id -g $ServerUID) $(id -g $ServerUID),$(id -g inet),$(id -g media_rw) $CORE_BOOT
    if [ server_check ]; then
        echo "[Info]: Server start [$(date +'%d/%r')]"
        return 0
    else
        echo '[Error]: start server failed.'
        exit 1
    fi
}

save_values() {
    service_check
    [ "$?" != '3' ] && { iptrules_off; killall -s 9 $CORE_BINARY >/dev/null 2>&1; echo "[Info]: Server stop"; }
    local tmp=$(grep "^$1=" $MODDIR/lib.sh)
    if [ "${2}" != 'bool' ]; then
        sed -i "s#^$tmp#$1=\'$2\'#g" $MODDIR/lib.sh
    else
        if [ "${3}" == 'true' -o "${3}" == 'false' ]; then
            sed -i "s#^$tmp#$1=$3#g" $MODDIR/lib.sh
        elif [[ "${3}" == -* || -z "${3}" ]]; then
            if [ "$(echo $tmp | awk -F "=" '{print $2}')" == 'true' ]; then
                sed -i "s#^$tmp#$1=false#g" $MODDIR/lib.sh
                return 2
            else
                sed -i "s#^$tmp#$1=true#g" $MODDIR/lib.sh
                return 1
            fi
        else
            echo "[Error]: Invalid value: $3"
            exit 1
        fi
    fi
    return 0
}

## Check
iptrules_check() {
    if [ -n "`$IPT -t nat -S | grep -E "REDIRECT --to-ports ${Listen_PORT}"`" ]; then
        echo '[Info]: iprules √'; return 0
    else
        echo '[Info]: iprules ×'; return 1
    fi
}

server_check() {
    local pid_file=$ROOT/server.pid
    [ -f ${pid_file} ] && local cmd_file="/proc/`cat ${pid_file}`/cmdline" || return 1
    [ -f ${cmd_file} ] && grep -q $CORE_DIR/$CORE_BINARY ${cmd_file} && return 0 || return 1
}

service_check() {
    local i=0
    server_check && echo '[Info]: Server √' || { echo '[Info]: Server ×'; i=`expr $i + 2`; }
    [ $Mode == 'server' ] || iptrules_check || let i++
    case ${i} in
        3)  # Not working
            return 3 ;;
        2)  # Server not working
            return 2 ;;
        1)  # iptrules not load
            return 1 ;;
        0)  # Working
            return 0 ;;
    esac
}

# Legality
port_valid() {
    if [ -n "`echo $2 | grep -E '(^[1-9][0-9]{0,3}$)|(^[1-5][0-9]{4}$)|(^6[0-5]{2}[0-3][0-5]$)'`" ]; then
        return 0
    else
        echo "[Error]: Invalid value: $2"
        exit 1
    fi
}