#!/usr/bin/env bash
# https://humdi.net/vnstat/
yum install -q -y gcc gcc-c++ make sqlite-devel || apt install -y build-essential sqlite3 libsqlite3-dev
wget https://humdi.net/vnstat/vnstat-2.7.tar.gz
tar zxvf vnstat-2.7.tar.gz
cd vnstat-2.7
./configure --prefix=/etc/vnstat
make -j $(cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l)
make install
#修改刷新时间为1分钟
sed -i '/^SaveInterval/s/.*/SaveInterval 1/g' /etc/vnstat/etc/vnstat.conf
ln -s /etc/vnstat/bin/vnstat /usr/bin/vnstat
ln -s /etc/vnstat/bin/vnstati /usr/bin/vnstati
ln -s /etc/vnstat/sbin/vnstatd /usr/bin/vnstatd

echo "[Unit]
Description=vnstat守护程序
After=network.target

[Service]
User=root
ExecStart=/etc/vnstat/sbin/vnstatd -n --config /etc/vnstat/etc/vnstat.conf
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/vnstat.service

systemctl daemon-reload
systemctl start vnstat
systemctl enable vnstat
chmod -R 777 /var/lib/vnstat
