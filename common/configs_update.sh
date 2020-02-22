#!/system/bin/sh
# From Aefer @ github
MODDIR=/data/adb/modules/smartdns
. ${0%/*}/lib.sh || { echo "Error: Can't load lib!"; exit 1; }
LOCAL_DIR="/data/local/tmp/smartdns"
rm -rf $LOCAL_DIR
mkdir $LOCAL_DIR
cd $LOCAL_DIR
local pid tmp file new

printf 'info: 开始下载配置\n'
wget -O yhosts_ip.txt.tmp https://raw.githubusercontent.com/vokins/yhosts/master/dnsmasq/ip.conf
pid=$!
wait $pid

wget -O gfwlist.txt.tmp https://cokebar.github.io/gfwlist2dnsmasq/dnsmasq_gfwlist.conf
pid=$!
wait $pid
sed -i 's/server/nameserver/;s/127.0.0.1#5353/secure/' gfwlist.txt.tmp &

wget -O googlehosts.txt.tmp https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/dnsmasq.conf
pid=$!
wait $pid

wget -O googlehosts_ipv6.txt.tmp https://raw.githubusercontent.com/googlehosts/hosts-ipv6/master/hosts-files/dnsmasq.conf
pid=$!
wait $pid

wget -O suspect_ip.tmp https://raw.githubusercontent.com/stamparm/ipsum/master/levels/7.txt
pid=$!
wait $pid
awk '/^1/ {printf"ignore-ip %s\n",$1}' suspect_ip.tmp > suspect_ip.txt && rm suspect_ip.tmp &

wget -O hosts_ipv6_lennylxx.tmp https://raw.githubusercontent.com/lennylxx/ipv6-hosts/master/hosts && dos2unix hosts_ipv6_lennylxx.tmp &
pid=$!
wait $pid
awk '/^2/ {printf"address /%s/%s\n",$2,$1}' hosts_ipv6_lennylxx.tmp > hosts_ipv6_lennylxx.txt &

printf 'info: 文件下载完成，开始处理\n'

for tmp in "github." "githubusercontent\." "\/translate\.google" "gvt1\.com" "localhost" "loopback" "^#" "^$"
do
    sed -i "/${tmp}/d" *.tmp
done
sed -i 's/=/ /' *.tmp

printf 'info: 配置处理完成\ninfo: 开始下载hosts\n'


# 国内
#wget -O hosts_AD-hosts.tmp https://raw.githubusercontent.com/E7KMbb/AD-hosts/master/system/etc/hosts
#pid=$!
#wait $pid

wget -O hosts_yhosts_union.tmp https://raw.githubusercontent.com/vokins/yhosts/master/dnsmasq/union.conf && sed -i 's/=\/./ \//' hosts_yhosts_union.tmp &
pid=$!
wait $pid

#wget -O hosts_yhosts.tmp https://raw.githubusercontent.com/vokins/yhosts/master/hosts.txt && sed -i '/^@/d' hosts_yhosts.tmp &
#pid=$!
#wait $pid

wget -O hosts_neo.tmp https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/full/hosts && dos2unix hosts_neo.tmp &
pid=$!
wait $pid

#国外
#wget -O hosts_PL.tmp 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext'
#pid=$!
#wait $pid

#wget -O hosts_malware.tmp.1 https://mirror1.malwaredomains.com/files/domains.hosts && awk -F '#' '($1) {print $1}' hosts_malware.tmp.1 > hosts_malware.tmp && rm -f hosts_malware.tmp.1 &
#pid=$!
#wait $pid

#wget -O hosts_adwars.tmp https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
#pid=$!
#wait $pid

#wget -O hosts_hp.tmp https://hosts-file.net/ad_servers.txt
#pid=$!
#wait $pid

wget -O hosts_adaway.tmp https://adaway.org/hosts.txt
pid=$!
wait $pid

wget -O hosts_adguard.tmp https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt
pid=$!
wait $pid

printf 'info: 文件下载完成，开始处理\n'

cat hosts_*.tmp > hosts_all
rm -rf hosts_*.tmp
for tmp in "gvt2\.com" "推广" "localhost" "loopback" "^#" "^$"
do
    sed -i "/${tmp}/d" hosts_all
done
sed -i 's/127.0.0.1/#/;s/0.0.0.0/#/;s/::1/#/;s/::/#/' hosts_all
sort -u hosts_all > hosts_all.tmp
awk '/^#/ {printf"address /%s/%s\n",$2,$1}' hosts_all.tmp > hosts_block.txt && rm -f hosts_all hosts_all.tmp

printf 'info: hosts处理完成\n'

for file in `find . -name "*.tmp"`
do
	new=`echo $file | sed 's/\.tmp//'`
	mv $file $new
done
[ ! -d $DATA_DIR/update ] && mkdir $DATA_DIR/update
mv ./* $DATA_DIR/update && printf 'info: 文件已更新\n'
rm -rf $LOCAL_DIR

exit 0