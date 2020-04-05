#!/system/bin/sh
# From Aefer @ github
MODDIR=/data/adb/modules/smartdns
. $MODDIR/lib.sh || { echo "[Error]: Can't load lib!"; exit 1; }
LOCAL_DIR="/data/local/tmp/smartdns"
rm -rf $LOCAL_DIR
mkdir $LOCAL_DIR
cd $LOCAL_DIR
local tmp file new

printf '[Info]: 开始下载配置\n'
#wget -O yhosts_ip.txt.tmp https://raw.githubusercontent.com/vokins/yhosts/master/dnsmasq/ip.conf &
#pid0=$!

wget -O gfwlist.txt.tmp https://cokebar.github.io/gfwlist2dnsmasq/dnsmasq_gfwlist.conf &
pid1=$!

wget -O accelerated-domains.china.txt.tmp https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf &
pid2=$!

#wait $pid0
wait $pid1; sed -i 's/server/nameserver/;s/127.0.0.1#5353/foreign/' gfwlist.txt.tmp
wait $pid2; sed -i 's/server/nameserver/;s/114.114.114.114/China/' accelerated-domains.china.txt.tmp

wget -O googlehosts.txt.tmp https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/dnsmasq.conf &
pid3=$!

wget -O googlehosts_ipv6.txt.tmp https://raw.githubusercontent.com/googlehosts/hosts-ipv6/master/hosts-files/dnsmasq.conf &
pid4=$!

#wget -O hosts_ipv6_lennylxx.tmp https://raw.githubusercontent.com/lennylxx/ipv6-hosts/master/hosts && dos2unix hosts_ipv6_lennylxx.tmp &
#pid5=$!

wait $pid3
wait $pid4
#wait $pid5; awk '/^2/ {printf"address /%s/%s\n",$2,$1}' hosts_ipv6_lennylxx.tmp > hosts_ipv6_lennylxx.txt && rm hosts_ipv6_lennylxx.tmp

printf '[Info]: 文件下载完成，开始处理\n'

for tmp in "dlsite\." "github\." "githubusercontent\." "\/translate\.google" "gvt0\.com" "gvt1\.com" "gvt3\.com" "localhost" "loopback" "^#" "^$"
do
    sed -i "/${tmp}/d" *.tmp
done
sed -i 's/=/ /' *.tmp

for file in `find . -name "*.tmp"`
do
    new=`echo $file | sed 's/\.tmp//'`
    mv $file $new
done

printf '[Info]: 配置处理完成\n[Info]: 开始下载hosts\n'


# 国内
#激进wget -O hosts_AD-hosts.tmp https://raw.githubusercontent.com/ &
#pid0=$!

#wget -O hosts_yhosts_union.tmp https://raw.githubusercontent.com/vokins/yhosts/master/dnsmasq/union.conf && sed -i 's/=\/./ \//' hosts_yhosts_union.tmp &
#pid1=$!

#wget -O hosts_yhosts.tmp https://raw.githubusercontent.com/vokins/yhosts/master/hosts.txt && sed -i '/^@/d' hosts_yhosts.tmp &
#pid2=$!

wget -O hosts_neo.tmp https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/full/hosts && dos2unix hosts_neo.tmp &
pid3=$!

#wait $pid0
#wait $pid1
#wait $pid2
wait $pid3

#国外

wget -O hosts_adguard.tmp https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt &
pid0=$!

wget -O hosts_adaway.tmp https://adaway.org/hosts.txt &
pid1=$!

#wget -O hosts_hp.tmp https://hosts-file.net/ad_servers.txt &
#pid2=$!

wait $pid0
wait $pid1
#wait $pid2

#wget -O hosts_adwars.tmp https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts &

#pid3=$!

#wget -O hosts_malware.tmp.1 https://mirror1.malwaredomains.com/files/domains.hosts && awk -F '#' '($1) {print $1}' hosts_malware.tmp.1 > hosts_malware.tmp && rm -f hosts_malware.tmp.1 &
#pid4=$!

#wget -O hosts_PL.tmp 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext' &
#pid5=$!

#wait $pid3
#wait $pid4
#wait $pid5

printf '[Info]: 文件下载完成，开始处理\n'

cat hosts_*.tmp > hosts_all
rm -rf hosts_*.tmp
for tmp in "gvt2\.com" "推广" "localhost" "loopback" "^#" "^$"
do
    sed -i "/${tmp}/d" hosts_all
done
sed -i 's/127.0.0.1/#/;s/0.0.0.0/#/;s/::1/#/;s/::/#/' hosts_all
sort -u hosts_all > hosts_all.tmp && rm hosts_all
awk '/^#/ {printf"address /%s/%s\n",$2,$1}' hosts_all.tmp > hosts_block.txt && rm hosts_all.tmp

printf '[Info]: hosts处理完成\n'

for file in `find . -name "*.tmp"`
do
    new=`echo $file | sed 's/\.tmp//'`
    mv $file $new
done
find . -name "*" -type f -size 0c | xargs -n 1 rm -f
[ ! -d $DATA_DIR/update ] && { mkdir $DATA_DIR/update; chmod 0770 $DATA_DIR/update; }
mv ./* $DATA_DIR/update && printf '[Info]: 文件已更新\n'
rm -rf $LOCAL_DIR

exit 0