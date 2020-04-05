#!/system/bin/sh
MODDIR=/data/adb/modules/smartdns
[[ $(id -u) -ne 0 ]] && { echo "${MODDIR##\/*\/}: Permission denied"; exit 1; }
[ -e $MODDIR/disable ] && { echo "${MODDIR##\/*\/}: Module disable"; exit 1; }
#set -x
usage() {
cat << HELP
Valid options are:
    -start
        Start Service
    -stop
        Stop Service
    -status
        Service Status
    -clean
        Restore origin rules and stop server
    -h, --help
        Get help
    -m, --mode [ local / proxy / server ]
        ├─ local: Proxy local only
        ├─ proxy: Proxy local and other query
        └─ server: Expecting the server only
    -p, --port [ main / route ] {port}
        Change port
    --ip6block [ true/false ]
        Block IPv6 port 53 output or Redirect query
    --vpn
        Redirect VPN query
    --strict [ true/false ]
        Limit queries from non-LAN
    -u, --user [ radio / root ]
        Server permission
HELP
    exit $1
}

## 防火墙
# 主控
iptrules_on() {
    [ "$Mode" == 'server' ] && return 0
    iptrules_load $IPT -I
    ip6trules_switch -I
    return 0
}

iptrules_off() {
    [ "$Mode" == 'server' ] && return 0
    local i=0
    while iptrules_check; do
        iptrules_load $IPT -D
        ip6trules_switch -D
        [[ ${i} > 2 ]] && { echo '[Error]: iptrules error.\n[Warning]: Run \`~ -clean\` to reset iptrules.'; exit 1; } || let i++
    done
    return 0
}

ip6trules_switch() {
    if [ "$IP6T_block" == 'true' ]; then
        $IP6T -t filter $1 OUTPUT ${VPN} -p tcp --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j REJECT --reject-with tcp-reset
        $IP6T -t filter $1 OUTPUT ${VPN} -p udp --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j DROP
    else
        iptrules_load $IP6T $1
    fi
}

# 加载
iptrules_load() {
    # $1 [ iptables / ip6tables] $2 [ -I / -D ]
    echo "[Info]: ${1##\/*\/} $2"
    local IPP subnet
    for IPP in 'tcp' 'udp'
    do
        # LOCAL
        $1 -t nat $2 OUTPUT -p ${IPP} -m mark --mark 0x653 -j REDIRECT --to-ports $Listen_PORT
        $1 -t nat $2 OUTPUT ${VPN} -p ${IPP} --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j MARK --set-xmark 0x653
        # IPv4 / IPv6
        if [ "${1}" == "$IPT" ]; then
            # IPv4 LOCAL
            $1 -t nat $2 POSTROUTING -p ${IPP} -m mark --mark 0x653 -j SNAT --to-source 127.0.0.1
            if [ "$Mode" == 'proxy' ]; then
                if [ "$Strict" == 'true' ]; then
                    # IPv4 EXTERNAL
                    for subnet in '10.0.0.0/8' '172.16.0.0/12' '192.168.0.0/16'; do
                        $1 -t nat $2 PREROUTING -p ${IPP} -s ${subnet} --dport 53 -j REDIRECT --to-ports $Route_PORT
                    done
                else
                    $1 -t nat $2 PREROUTING -p ${IPP} --dport 53 -j REDIRECT --to-ports $Route_PORT
                fi
            fi
        else
            # IPv6 LOCAL
            $1 -t nat $2 POSTROUTING -p ${IPP} -m mark --mark 0x653 -j SNAT --to-source ::1
            if [ "$Mode" == 'proxy' ]; then
                if [ "$Strict" == 'true' ]; then
                    # IPv6 EXTERNAL
                    $1 -t nat $2 PREROUTING -p ${IPP} -s fec0::/10 --dport 53 -j REDIRECT --to-ports $Route_PORT
                else
                    $1 -t nat $2 PREROUTING -p ${IPP} --dport 53 -j REDIRECT --to-ports $Route_PORT
                fi
            fi
        fi
    done
}

### Main
get_args() {
    while [ ${#} -gt 0 ]; do
        case "${1}" in
            -h|--help) # 帮助信息
                usage 0
                ;;

            -start) # 启动
                iptrules_off
                server_start && iptrules_on
                ;;

            -stop) # 停止
                iptrules_off
                killall -s 9 $CORE_BINARY >/dev/null 2>&1
                echo "[Info]: Server stop [$(date +'%d/%r')]"
                ;;

            -status) # 检查状态
                service_check
                exit $?
                ;;

            -clean) # 清除
                iptables -F
                ip6tables -F
                iptables-restore < $ROOT/origin.iptables
                ip6tables-restore < $ROOT/origin.ip6tables
                killall -s 9 $CORE_BINARY >/dev/null 2>&1
                echo "[Info]: All clean [$(date +'%d/%r')]"
                ;;

            # 修改数值
            -p|--port) # 端口设定
                case "${2}" in
                    r*)
                        shift; if [ port_valid ]; then
                            save_values Route_PORT $2
                            Route_PORT=$2
                        fi
                        ;;
                    *)
                        [[ "${2}" == m* ]] && shift
                        if [ port_valid ]; then
                            save_values Listen_PORT $2
                            Listen_PORT=$2
                        fi
                        ;;
                esac
                shift
                ;;

            -m|--mode) # 工作模式
                case "${2}" in
                    'local'|'proxy'|'server')
                        save_values Mode $2
                        Mode=$2
                        ;;
                    *)
                        echo "[Error]: Invalid value: $2"
                        exit 1
                        ;;
                esac
                shift
                ;;

            -u|--user) # 服务器权级
                case "${2}" in
                    radio|root)
                        save_values ServerUID $2
                        ServerUID=$2
                        ;;
                    *)
                        echo "[Error]: Invalid value: $2"
                        exit 1
                        ;;
                esac
                shift
                ;;

            --ip6block) # IPv6
                save_values IP6T_block bool $2
                case "$?" in
                    0)  IP6T_block=$2 ; shift ;;
                    1)  IP6T_block=true ;;
                    2)  IP6T_block=false ;;
                esac
                ;;

            --vpn) # VPN
                save_values VPN bool $2
                case "$?" in
                    0)  VPN=$2 ; shift ;;
                    1)  VPN=true ;;
                    2)  VPN=false ;;
                esac
                ;;

            --strict) # 限制
                save_values Strict bool $2
                case "$?" in
                    0)  Strict=$2 ; shift ;;
                    1)  Strict=true ;;
                    2)  Strict=false ;;
                esac
                ;;

            *)
                echo "[Error]: Invalid argument: $1\n"
                usage 1
                ;;

            esac
        shift
    done
}

main() {
    . $MODDIR/lib.sh || { echo "[Error]: Can't load lib!"; exit 1; }
    [ -z $Route_PORT ] && Route_PORT=$Listen_PORT
    [ "$VPN" == 'true' ] && VPN='' || VPN='! -o tun+'

    if [ "${1}" == '--b' ]; then
        shift
        $CORE_DIR/$CORE_BINARY $*
    elif [ "${1}" == '-b' ]; then
        shift
        $CORE_BOOT $*
    else
        if [ -z ${1} ]; then
            usage 0
        else
            get_args "$@"
        fi
    fi
}

main "$@"