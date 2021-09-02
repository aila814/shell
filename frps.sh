#!/bin/bash
blue="\033[34m\033[01m"
green="\033[32m\033[01m"
yellow="\033[33m\033[01m"
red="\033[31m\033[01m"
Font="\033[0m"

#安装frps
install(){

    if [[ $(cat /etc/os-release | grep -w ID | sed 's/ID=//' | sed 's/\"//g') == "centos" ]]; then
        if [[ -z $(command -v lsof) ]]; then
        yum install -y lsof
        fi
    else
        if [[ -z $(command -v lsof) ]]; then
        apt install -y lsof
        fi
        if [[ -z $(command -v ufw) ]]; then
        apt-get update -y && apt-get install ufw -y
        ufw enable
        fi
    fi
    
    # 获取最新版本
    frps_url=$(curl -s https://github.com/fatedier/frp/releases.atom | grep '<link rel="alternate" type="text\/html" href=' | sed 's/^.*href="//g' | sed 's/"\/>//g' | head -1)
    # 最新版本
    frps_update_version=${frps_url##*/v}
    # 架构
    Arch="linux_amd64"
    # 版本
    frps_version="${frps_update_version}"
    # 
    [[ -z ${frps_update_version} ]] && exit 0
    url="https://github.com/fatedier/frp/releases/download/v${frps_version}/frp_${frps_version}_${Arch}.tar.gz"
    
	[[ ! -d "/etc/frps" ]] && mkdir /etc/frps
	cd /etc/frps
	echo -e "$green[INFO]$Font 开始下载:$frps_version"
	wget -q -O "${frps_version}.tar.gz" $url
	tar zxf "${frps_version}.tar.gz"
	cp -f ./frp_${frps_version}_linux_amd64/frps ./
	rm -rf "frp_${frps_version}_linux_amd64" "${frps_version}.tar.gz"
	chmod +x /etc/frps/frps
    [[ ! -f "/etc/frps/frps.ini" ]] && 	echo -e "[common]
# 连接端口
bind_port=7000
# kcp连接端口
kcp_bind_port=7001
# udp连接端口
bind_udp_port=7002
# http端口
vhost_http_port=80
# https端口
vhost_https_port=443
# 连接密码
token=123456
# web面板端口
# dashboard_port=7500
# web面板账号
# dashboard_user=admin
# web面板密码
# dashboard_pwd=admin
# 用于二级域名访问 泛解析到服务器ip
# subdomain_host=baidu.com
# 自定义错误页面
# custom_404_page=./404.html" > /etc/frps/frps.ini

	
echo -e "[Unit]
Description=frps
After=network.target

[Service]
User=root
Restart=always
RestartSec=3s
ExecStart=/etc/frps/frps -c /etc/frps/frps.ini

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/frps.service
systemctl daemon-reload
systemctl enable frps
}
#卸载
uninstall(){
	systemctl stop frps
	systemctl disable frps
	rm -rf /etc/frps
	rm -rf /etc/systemd/system/frps.service
}

# 启动
start(){
systemctl start frps
sleep 0.5s
if [[ -n $(systemctl status frps | grep "Active" | grep "running") ]]; then
	echo -e "$green[INFO]$Font 已启动"
	else
	echo -e "$red[INFO]$Font 启动失败"
fi

}
# 停止
stop(){
systemctl stop frps
sleep 0.5s
if [[ -z $(systemctl status frps | grep "Active" | grep "running") ]]; then
	echo -e "$green[INFO]$Font 已关闭"
fi

}
# 重启
restart(){
systemctl restart frps
sleep 0.5s
if [[ -n $(systemctl status frps | grep "Active" | grep "running")  ]]; then
	echo -e "$green[INFO]$Font 已重启"
	else
	echo -e "$red[INFO]$Font 未能重启,进程已关闭"
fi

}
frps_pid(){
if [[ -n $(systemctl status frps | grep "Active" | grep "running") ]]; then
	echo -e "$green[INFO]$Font 运行中"
	echo -e "进程PID：$(systemctl status frps |grep "Main PID:"| cut -d " " -f4)"
	else
	echo -e "$red[INFO]$Font 未运行"
fi
}
add_port(){
    if [[ $(cat /etc/os-release | grep -w ID | sed 's/ID=//' | sed 's/\"//g') == "centos" ]]; then
        firewall-cmd --zone=public --add-port=$1/tcp --permanent
		firewall-cmd --zone=public --add-port=$1/udp --permanent
		firewall-cmd --reload
		else
		ufw allow $1/tcp
	    ufw allow $1/udp
    fi
    
}
Detection_port(){
kcp_port=$(awk -F'=' '/kcp_bind_port/{print $2}' /etc/frps/frps.ini)
udp_port=$(awk -F'=' '/bind_udp_port/{print $2}' /etc/frps/frps.ini)
http=$(awk -F'=' '/vhost_http_port/{print $2}' /etc/frps/frps.ini)
https=$(awk -F'=' '/vhost_https_port/{print $2}' /etc/frps/frps.ini)
port=$(awk -F'=' '/^bind_port/{print $2}' /etc/frps/frps.ini)
token=$(awk -F'=' '/token/{print $2}' /etc/frps/frps.ini)
if [[ -n $(lsof -i:$kcp_port) ]]; then
	echo -e "$red[INFO]$Font KCP端口已使用"
elif [[ -n $(lsof -i:$udp_port) ]]; then
	echo -e "$red[INFO]$Font UDP端口已使用"
elif [[ -n $(lsof -i:$http) ]]; then
	echo -e "$red[INFO]$Font HTTP端口已使用"
elif [[ -n $(lsof -i:$https) ]]; then
	echo -e "$red[INFO]$Font HTTPS端口已使用"
elif [[ -n $(lsof -i:$port) ]]; then
	echo -e "$red[INFO]$Font 连接端口已使用"
else
    start
fi

}

# 查看配置信息
frps_1(){
kcp_port=$(awk -F'=' '/kcp_bind_port/{print $2}' /etc/frps/frps.ini)
udp_port=$(awk -F'=' '/bind_udp_port/{print $2}' /etc/frps/frps.ini)
http=$(awk -F'=' '/vhost_http_port/{print $2}' /etc/frps/frps.ini)
https=$(awk -F'=' '/vhost_https_port/{print $2}' /etc/frps/frps.ini)
port=$(awk -F'=' '/^bind_port/{print $2}' /etc/frps/frps.ini)
token=$(awk -F'=' '/token/{print $2}' /etc/frps/frps.ini)
echo "———————————————————————————"
echo "frps版本："$(/etc/frps/frps -v)
echo "程序路径：/etc/frps/frps"
echo "配置文件路径：/etc/frps/frps.ini"
echo "———————————————————————————"
echo "连接端口：$port"
echo "KCP端口：$kcp_port"
echo "UDP端口：$udp_port"
echo "HTTP端口：$http"
echo "HTTPS端口：$https"
echo "token：$token"
}
# 修改配置信息
frp_edit(){
echo -e $green'  1. '$Font'修改连接端口'
echo -e $green'  2. '$Font'修改HTTP端口'
echo -e $green'  3. '$Font'修改HTTPS端口'
echo -e $green'  4. '$Font'修改TOKEN'
echo -e $green'  5. '$Font'修改KCP端口'
echo -e $green'  6. '$Font'修改UDP端口'
echo -e $green'  0. '$Font'退出'
read -p "输入序号: " x
if [[ "$x" == "0" ]]; then
    exit
fi
if [[ "$x" == "1" ]]; then
	read -p "连接端口: " tmp
	if [[ -n $(lsof -i:$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/^bind_port/s/.*/bind_port='$tmp'/g' /etc/frps/frps.ini
        add_port $tmp
	fi
	
	
fi
if [[ "$x" == "2" ]]; then
	read -p "HTTSP端口: " tmp
	if [[ -n $(lsof -i:$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/vhost_http_port/s/.*/vhost_http_port='$tmp'/g' /etc/frps/frps.ini
        add_port $tmp
	fi
	
fi
if [[ "$x" == "3" ]]; then
	read -p "HTTPS端口: " tmp
	if [[ -n $(lsof -i:$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/vhost_https_port/s/.*/vhost_https_port='$tmp'/g' /etc/frps/frps.ini
	    add_port $tmp
	fi
	
fi
if [[ "$x" == "4" ]]; then
	read -p "输入TOKEN: " tmp

	   	if [[ -n  $tmp ]]; then
	    sed -i '/token/s/.*/token='$tmp'/g' /etc/frps/frps.ini
	    fi

fi
if [[ "$x" == "5" ]]; then
	read -p "KCP端口: " tmp
	if [[ -n $(lsof -i:$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/kcp_bind_port/s/.*/kcp_bind_port='$tmp'/g' /etc/frps/frps.ini
	    add_port $tmp
	fi
	
fi
if [[ "$x" == "6" ]]; then
	read -p "UDP端口: " tmp
	if [[ -n $(lsof -i:$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/bind_udp_port/s/.*/bind_udp_port='$tmp'/g' /etc/frps/frps.ini
	    add_port $tmp
	fi
	
fi
frp_edit
}


home(){
echo -e $green'  1. '$Font'安装'
echo -e $green'  2. '$Font'卸载'
echo "———————————————————————————"
echo -e $green'  3. '$Font'启动'
echo -e $green'  4. '$Font'停止'
echo -e $green'  5. '$Font'重启'
echo "———————————————————————————"
echo -e $green'  6. '$Font'查看配置信息'
echo -e $green'  7. '$Font'查看进程信息'
echo -e $green'  8. '$Font'修改端口'
frps_pid


read -p "输入序号: " x
if [[ "$x" == "1" ]]; then
	install
fi
if [[ "$x" == "2" ]]; then
	uninstall
fi
if [[ "$x" == "3" ]]; then
	if [[ ! -d /etc/frps ]]; then
		echo -e "$red[INFO]$Font 未安装"
	else
		Detection_port
	fi

fi
if [[ "$x" == "4" ]]; then
	if [[ ! -d /etc/frps ]]; then
		echo -e "$red[INFO]$Font 未安装"
	else
		stop
	fi
fi
if [[ "$x" == "5" ]]; then
	if [[ ! -d /etc/frps ]]; then
		echo -e "$red[INFO]$Font 未安装"
	else
		restart
	fi
fi
if [[ "$x" == "6" ]]; then
	if [[ ! -d /etc/frps ]]; then
		echo -e "$red[INFO]$Font 未安装"
	else
		frps_1
	fi
	
fi
if [[ "$x" == "7" ]]; then
	if [[ ! -d /etc/frps ]]; then
		echo -e "$red[INFO]$Font 未安装"
	else
		systemctl status frps
	fi
fi
if [[ "$x" == "8" ]]; then
	if [[ ! -d /etc/frps ]]; then
		echo -e "$red[INFO]$Font 未安装"
	else
		frp_edit
	fi
	
fi
if [[ "$x" == "9" ]]; then
	Detection_port
fi
}
home



