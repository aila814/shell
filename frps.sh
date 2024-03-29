#!/usr/bin/env bash
# curl -s https://api.github.com/repos/fatedier/frp/releases/latest | jq -r  .tag_name| sed s/[a-zA-Z]//g
# curl -s https://api.github.com/repos/fatedier/frp/releases/latest | jq -r  .assets[].browser_download_url

_echo(){
green="\033[32m\033[01m"
red="\033[31m\033[01m"
Font="\033[0m"
if [[ $2 == 1 ]]; then
    echo -e "$green[信息]$Font $1"
fi
if [[ $2 == 11 ]]; then
    echo -e "$green$1$Font"
fi
if [[ $2 == 0 ]]; then
    echo -e "$red[错误]$Font $1"
fi
if [[ $2 == 00 ]]; then
    echo -e "$red$1$Font"
fi
}

# 安装依赖
if [[ -z  $(command -v jq) ]]; then
    if [[ $(cat /etc/os-release | grep -w ID | sed 's/ID=//' | sed 's/\"//g') == "centos" ]]; then
	    yum install jq -y
		else   
		apt update -y
		apt install jq -y
    fi
fi




# 更新
update(){
version_info=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest)
version=$(grep "tag_name" <<< "$version_info" | sed 's/tag_name//g;s/"//g;s/ //g;s/://g;s/,//g;s/v//g')
download_url=$(grep "browser_download_url" <<< "$version_info" | sed 's/browser_download_url//g;s/"//g;s/ //g;s/://g;s/,//g;s/\/\//:\/\//g' | grep "linux_amd64")
[[ -z "$version" ]] && _echo "获取版本失败" 0 && exit
local_version=$(/etc/frps/frps -v)
_echo "本地版本: $local_version" 1
_echo "最新版本: $version" 1
if [[ "$local_version" == "$version" ]]; then
    _echo "版本一致,无需更新" 1
    exit
    else
    _echo "停止frps" 1 && stop
    _echo "开始更新..." 1
    wget -q "${download_url}" -O /etc/frps/frps.tar.gz
    tar zxf /etc/frps/frps.tar.gz -C /etc/frps > /dev/null
    mv /etc/frps/frp_*/frps /etc/frps
    chmod +x /etc/frps/frps
    rm -rf /etc/frps/frp_* /etc/frps/frps.tar.gz
    _echo "更新完成" 1
    _echo "启动frps" 1 && start
fi

}
# 安装
install(){
version_info=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest)
version=$(grep "tag_name" <<< "$version_info" | sed 's/tag_name//g;s/"//g;s/ //g;s/://g;s/,//g')
download_url=$(grep "browser_download_url" <<< "$version_info" | sed 's/browser_download_url//g;s/"//g;s/ //g;s/://g;s/,//g;s/\/\//:\/\//g' | grep "linux_amd64")
if [[ -z "$version" ]]; then
    _echo "获取版本失败" 0
    exit
    else
    [[ ! -d "/etc/frps" ]] && mkdir "/etc/frps"
    rm -rf /etc/frps/*
    _echo "最新版本: $version" 1
    _echo "开始下载..." 1
    wget -q "${download_url}" -O /etc/frps/frps.tar.gz
    tar zxvf /etc/frps/frps.tar.gz -C /etc/frps > /dev/null
    mv /etc/frps/frp_*/frps /etc/frps
    chmod +x /etc/frps/frps
    rm -rf /etc/frps/frp_* /etc/frps/frps.tar.gz
    read -p "连接端口(默认7000): " port && [[ -z $port ]] && port="7000"
    read -p "KCP端口(默认7001): " kcp_port && [[ -z $kcp_port ]] && kcp_port="7001"
    read -p "UDP端口(默认7002): " udp_port && [[ -z $udp_port ]] && udp_port="7002"
    read -p "HTTP端口(默认80): " http_port && [[ -z $http_port ]] && http_port="80"
    read -p "HTTPS端口(默认443): " https_port && [[ -z $https_port ]] && https_port="443"
    read -p "token,连接密码(默认123456): " token && [[ -z $token ]] && token="123456"
[[ ! -f "/etc/frps/frps.ini" ]] && 	echo -e "[common]
# 连接端口
bind_port=$port
# kcp连接端口
kcp_bind_port=$kcp_port
# udp连接端口
bind_udp_port=$udp_port
# http端口
vhost_http_port=$http_port
# https端口
vhost_https_port=$https_port
# 连接密码
token=$token
# 日志文件位置
log_file=/etc/frps/frps.log
# web面板端口
dashboard_port=7500
# web面板账号
dashboard_user=admin
# web面板密码
dashboard_pwd=admin
# 用于二级域名访问 泛解析到服务器ip
# subdomain_host=baidu.com
# 自定义错误页面
# custom_404_page=./404.html" > /etc/frps/frps.ini
[[ ! -f "/lib/systemd/system/frps.service" ]] && 	echo -e "[Unit]
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
_echo "安装完成!" 1
_echo "启动frps..." 1
start
fi
}

#卸载
uninstall(){
	systemctl stop frps
	systemctl disable frps
	rm -rf /etc/frps
	rm -rf /lib/systemd/system/frps.service
    _echo "卸载完成!" 1	
}

# 启动
start(){
systemctl start frps
sleep 0.5s
if [[ -n $(systemctl status frps | grep "Active" | grep "running") ]]; then
	_echo "已启动" 1
	else
	_echo "启动失败" 0
fi

}
# 停止
stop(){
systemctl stop frps
sleep 0.5s
if [[ -z $(systemctl status frps | grep "Active" | grep "running") ]]; then
	_echo "已关闭" 1
fi

}
# 重启
restart(){
systemctl restart frps
sleep 0.5s
if [[ -n $(systemctl status frps | grep "Active" | grep "running")  ]]; then
	_echo "已重启" 1
	else
	_echo "未能重启,进程已关闭" 0
fi

}
frps_pid(){
if [[ -n $(systemctl status frps | grep "Active" | grep "running") ]]; then
	_echo "运行中" 1
	echo -e "进程PID：$(systemctl status frps |grep "Main PID:"| cut -d " " -f4)"
	else
	_echo "未运行" 0
fi
}
# 开放端口
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
# 检测端口
Detection_port(){
kcp_port=$(awk -F'=' '/kcp_bind_port/{print $2}' /etc/frps/frps.ini)
udp_port=$(awk -F'=' '/bind_udp_port/{print $2}' /etc/frps/frps.ini)
http=$(awk -F'=' '/vhost_http_port/{print $2}' /etc/frps/frps.ini)
https=$(awk -F'=' '/vhost_https_port/{print $2}' /etc/frps/frps.ini)
port=$(awk -F'=' '/^bind_port/{print $2}' /etc/frps/frps.ini)
token=$(awk -F'=' '/token/{print $2}' /etc/frps/frps.ini)
if [[ -n $(netstat -ntulp |grep :$kcp_port) ]]; then
	_echo "KCP端口已使用" 0
elif [[ -n $(netstat -ntulp |grep :$udp_port) ]]; then
	_echo "UDP端口已使用" 0
elif [[ -n $(netstat -ntulp |grep :$http) ]]; then
	_echo "HTTP端口已使用" 0
elif [[ -n $(netstat -ntulp |grep :$https) ]]; then
	_echo "HTTPS端口已使用" 0
elif [[ -n $(netstat -ntulp |grep :$port) ]]; then
	_echo "连接端口已使用" 0
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
echo "———————————————————————————"
echo "KCP端口：$kcp_port"
echo "———————————————————————————"
echo "UDP端口：$udp_port"
echo "———————————————————————————"
echo "HTTP端口：$http"
echo "———————————————————————————"
echo "HTTPS端口：$https"
echo "———————————————————————————"
echo "token：$token"
echo "———————————————————————————"
}
# 修改配置信息
frp_edit(){
echo -e '  1. 修改连接端口'
echo -e '  2. 修改HTTP端口'
echo -e '  3. 修改HTTPS端口'
echo -e '  4. 修改TOKEN'
echo -e '  5. 修改KCP端口'
echo -e '  6. 修改UDP端口'
echo -e '  0. 退出'
read -p "输入序号: " x
if [[ "$x" == "0" ]]; then
    exit
fi
if [[ "$x" == "1" ]]; then
	read -p "连接端口: " tmp
	if [[ -n $(netstat -ntulp |grep :$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/^bind_port/s/.*/bind_port='$tmp'/g' /etc/frps/frps.ini
        add_port $tmp
	fi
	
	
fi
if [[ "$x" == "2" ]]; then
	read -p "HTTP端口: " tmp
	if [[ -n $(netstat -ntulp |grep :$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/vhost_http_port/s/.*/vhost_http_port='$tmp'/g' /etc/frps/frps.ini
        add_port $tmp
	fi
	
fi
if [[ "$x" == "3" ]]; then
	read -p "HTTPS端口: " tmp
	if [[ -n $(netstat -ntulp |grep :$tmp) ]]; then
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
	if [[ -n $(netstat -ntulp |grep :$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/kcp_bind_port/s/.*/kcp_bind_port='$tmp'/g' /etc/frps/frps.ini
	    add_port $tmp
	fi
	
fi
if [[ "$x" == "6" ]]; then
	read -p "UDP端口: " tmp
	if [[ -n $(netstat -ntulp |grep :$tmp) ]]; then
	    echo -e "$red[INFO]$Font 端口已使用"
	    frp_edit
	    else
	    sed -i '/bind_udp_port/s/.*/bind_udp_port='$tmp'/g' /etc/frps/frps.ini
	    add_port $tmp
	fi
	
fi
frp_edit
}

[[ "$1" == "start" ]] && start && exit
[[ "$1" == "stop" ]] && stop && exit
[[ "$1" == "restart" ]] && restart && exit
[[ "$1" == "status" ]] && frps_pid && exit
[[ "$1" == "update" ]] && update && exit
home(){
echo -e '  0. 更新'
echo -e '  1. 安装'
echo -e '  2. 卸载'
if [[ -d "/etc/frps" ]]; then
echo "———————————————————————————"
echo -e '  3. 启动'
echo -e '  4. 停止'
echo -e '  5. 重启'
echo "———————————————————————————"
echo -e '  6. 查看配置信息'
echo -e '  7. 查看进程信息'
echo -e '  8. 修改端口'
echo -e '  9. 查看日志'
echo -e ' 10. 清空日志'
frps_pid
fi

read -p "输入序号: " x
if [[ "$x" == "0" ]]; then
	if [[ ! -d /etc/frps ]]; then
		_echo "未安装" 0
		exit
	else
		update
	fi
fi
if [[ "$x" == "1" ]]; then
	install
fi
if [[ "$x" == "2" ]]; then
	uninstall
fi
if [[ "$x" == "3" ]]; then
	if [[ ! -d /etc/frps ]]; then
		_echo "未安装" 0
	else
		Detection_port
	fi

fi
if [[ "$x" == "4" ]]; then
	if [[ ! -d /etc/frps ]]; then
		_echo "未安装" 0
	else
		stop
	fi
fi
if [[ "$x" == "5" ]]; then
	if [[ ! -d /etc/frps ]]; then
		_echo "未安装" 0
	else
		restart
	fi
fi
if [[ "$x" == "6" ]]; then
	if [[ ! -d /etc/frps ]]; then
		_echo "未安装" 0
	else
		frps_1
	fi
	
fi
if [[ "$x" == "7" ]]; then
	if [[ ! -d /etc/frps ]]; then
		_echo "未安装" 0
	else
		systemctl status frps
	fi
fi
if [[ "$x" == "8" ]]; then
	if [[ ! -d /etc/frps ]]; then
		_echo "未安装" 0
	else
		frp_edit
	fi
	
fi
if [[ "$x" == "9" ]]; then
	
	if [[ -f "/etc/frps/frps.log" ]]; then
        cat /etc/frps/frps.log 
	fi
fi
if [[ "$x" == "10" ]]; then
	
	if [[ -f "/etc/frps/frps.log" ]]; then
		> "/etc/frps/frps.log"
		_echo "已清空" 1
	fi
fi
}
home



