#!/system/bin/sh
# Convenient control script

[[ "$#" -eq 0 ]] && { echo "! Null input !"; exit 1; }
[[ $(id -u) -ne 0 ]] && { echo "! Need root !"; exit 1; }

V4LPT=53; V6LPT=53
ipt_block_INPUT=false
ipt_block_IPv6_OUTPUT=false

MODPATH=/data/adb/modules/smartdns
source $MODPATH/constant.sh

### Load iptables rules

function iptrules_load()
{
 IPS=$2; LIP=$3; LPT=$4
  for IPP in 'udp' 'tcp'
  do
    echo "$1 $IPS $IPP $LPT"
    $1 -t nat $IPS PREROUTING -p $IPP --dport 53 -j DNAT --to-destination $LIP:$LPT
    $1 -t nat $IPS PREROUTING -p $IPP -m owner --uid-owner 0 --dport 53 -j ACCEPT
  done
  if [ "$ipt_block_INPUT" == 'true' ]; then
    echo "Block INPUT $IPS"
    block_rules $IPTABLES $IPS INPUT 53
    block_rules $IP6TABLES $IPS INPUT 53
    if [ -n "$(echo $whitelist | grep -E '([0-255]\.){3}[0-255]')" ]; then
      accept_rules $IPTABLES $IPS INPUT 53
    fi
  fi
}

function ip6trules_load()
{
  if [ "$ipt_block_IPv6_OUTPUT" == 'true' ]; then
    echo "Block IPv6 OUTPUT $1"
    block_rules $IP6TABLES $1 OUTPUT 53
  else
    iptrules_load $IP6TABLES $1 '[::1]' $V6LPT
  fi
}

function accept_rules()
{
for IP in $whitelist
do
  $1 -t filter $2 $3 -p udp -d $IP --dport $4 -j ACCEPT
  $1 -t filter $2 $3 -p tcp -d $IP --dport $4 -j ACCEPT
done
}

function block_rules()
{
  $1 -t filter $2 $3 -p udp --dport $4 -j DROP
  $1 -t filter $2 $3 -p tcp --dport $4 -j REJECT --reject-with tcp-reset
}

# Check rules
function iptrules_check()
{
 r=0
  for IPP in 'udp' 'tcp'
  do
    [ -n "`$IPTABLES -n -t nat -L PREROUTING | grep "DNAT.*$IPP.*dpt:53.*to:"`" ] && ((r++))
    [ -n "`$IPTABLES -n -t nat -L PREROUTING | grep "ACCEPT.*$IPP.*owner.*UID.*dpt:53"`" ] && ((r++))
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
  echo "- Starting $(date +'%d/%r')"
  $CORE_BOOT &
  if [ ! core_check ]; then
    echo '(!) Fails: Core not working'; exit 1
  fi
}

### Processing options
 case $* in
  # Boot
  -start)
    iptrules_off
    core_start
    if core_check; then
      iptrules_on
    fi
  ;;
  # Boot Core only
  -start-core)
    core_start
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
 -reset
   Reset iptables
EOD
  ;;
#### Advanced Features
  # Clean iptables rules
  -reset)
    iptables -t nat -F OUTPUT
    ip6tables -t nat -F OUTPUT
    sleep 1
    iptables -t filter -F INPUT
    ip6tables -t filter -F INPUT
    sleep 1
    iptables -t filter -F OUTPUT
    ip6tables -t filter -F OUTPUT
    killall $CORE_BINARY
    echo '- Done'
  ;;
  # Pass command
  *)
    $CORE_PATH $*
  ;;
 esac
exit 0
