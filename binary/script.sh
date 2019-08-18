#!/system/bin/sh
# Convenient control script

[[ "$#" -eq 0 ]] && { echo "! Null input !"; exit 1; }
[[ $(id -u) -ne 0 ]] && { echo "! Need root !"; exit 1; }

[ -f /proc/net/ip6_tables_names ] && { ipt_setIPv6='true'; }||{ ipt_setIPv6='false'; }

MODPATH=/data/adb/modules/smartdns
source $MODPATH/constant.sh

function gconf(){ grep $1 $CONFIG; }

V4LPT=6453
V6LPT=6453

### Load iptables rules

function iptrules_load()
{
 IPT=$1; IPS=$2; LIP=$3; LPT=$4
  for IPP in 'udp' 'tcp'
  do
    echo "$IPT $IPS $IPP $LPT"
    $IPT -t nat $IPS OUTPUT -p $IPP --dport 53 -j DNAT --to-destination $LIP:$LPT
    $IPT -t nat $IPS OUTPUT -p $IPP -m owner --uid-owner 0 --dport 53 -j ACCEPT
  done
}

function ip6trules_load()
{
 IPS=$1;
  if [ "$ipt_setIPv6" == 'true' ]; then
    if [ "$ipt_blockIPv6" == 'true' ]; then
      blockIPv6 $IPS
    else
      iptrules_load $IP6TABLES $IPS '[::1]' $V6LPT
    fi
  else
    echo 'Skip IPv6'
  fi
}

function blockIPv6()
{
 echo "Block IPv6 $1";
  $IP6TABLES -t filter $1 OUTPUT -p udp --dport 53 -j DROP
  $IP6TABLES -t filter $1 OUTPUT -p tcp --dport 53 -j REJECT --reject-with tcp-reset
}

# Check rules
function iptrules_check()
{
 r=0
  for IPP in 'udp' 'tcp'
  do
    [ -n "`$IPTABLES -n -t nat -L OUTPUT | grep "DNAT.*$IPP.*dpt:53.*to:"`" ] && ((r++))
    [ -n "`$IPTABLES -n -t nat -L OUTPUT | grep "ACCEPT.*$IPP.*owner.*UID.*dpt:53"`" ] && ((r++))
  done
[ $r -gt 0 ] && return 0
}

function core_check()
{
 [ -n "`pgrep $CORE_BINARY`" ] && return 0
}

# Main
function iptrules_on()
{
  iptrules_load $IPTABLES '-I' '127.0.0.1' $V4LPT
  ip6trules_load '-I'
}

function iptrules_off()
{
  while iptrules_check; do
    iptrules_load $IPTABLES '-D' '127.0.0.1' $V4LPT
    ip6trules_load '-D'
  done
}

## Other

function core_start()
{
  core_check && killall $CORE_BINARY
  sleep 1
  echo "- Start working $(date +'%d/%r')"
  $CORE_BOOT &
}

### Processing options
 case $* in
  # Boot
  -start)
    iptrules_off
    core_start
    if core_check; then
      iptrules_on
    else
      echo '(!)Fails:Core not working'; exit 1
    fi
  ;;
  # Boot Core only
  -start-core)
    core_start
    if [ ! core_check ]; then
      echo '(!)Fails:Core not working'; exit 1
    fi
  ;;
  # Stop
  -stop)
    echo '- Stoping'
    iptrules_off
    killall $CORE_BINARY
    echo '- Done'
  ;;
  # Check status
  -status)
   i=0;
    core_check && { echo '< Core Online >'; }||{ echo '! Core Offline !'; i=`expr $i + 2`; }
    iptrules_check && { echo '< iprules Enabled >'; }||{ echo '! iprules Disabled !'; i=`expr $i + 1`; }
  [ $i == 3 ] && exit 11 #All
  [ $i == 2 ] && exit 01 #iprules
  [ $i == 1 ] && exit 10 #Core
  ;;
  # Help
  -usage)
cat <<EOD
Usage:
 -start
   Start Service
 -stop
   Stop Service
 -status
   Service Status
 -start-core
   Boot core only
 -reset-rules
   Reset iptables
EOD
  ;;
#### Advanced Features
  # Clean iptables rules
  -reset-rules)
    iptables -t nat -F OUTPUT
    ip6tables -t nat -F OUTPUT
    sleep 1
    blockIPv6 '-D'
    killall $CORE_BINARY
  echo '- Done'
  ;;
  # Pass command
  *)
    $CORE_PATH $*
  ;;
 esac
exit 0
