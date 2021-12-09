#!/usr/bin/env bash
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

install(){
version_info=$(curl -s https://api.github.com/repos/cloudreve/Cloudreve/releases/latest)
version=$(grep "tag_name" <<< "$version_info" | sed 's/tag_name//g;s/"//g;s/ //g;s/://g;s/,//g;s/v//g')
download_url=$(grep "browser_download_url" <<< "$version_info" | sed 's/browser_download_url//g;s/"//g;s/ //g;s/://g;s/,//g;s/\/\//:\/\//g' | grep "linux_amd64")
if [[ -z "$version" ]]; then
    _echo "获取版本失败" 0
    exit
    else
    _echo "最新版本: $version" 1
    read -p "安装目录(默认:/etc/cloudreve): " path
    [[ -z "$path" ]] && path="/etc/cloudreve"
    [[ ! -d "$path" ]] && mkdir "$path"
    _echo "开始下载..." 1
    wget -q -O "$path/cloudreve.tar.gz" $download_url
    tar zxf "$path/cloudreve.tar.gz" -C "$path"
    rm -rf "$path/cloudreve.tar.gz"
    chmod +x "$path/cloudreve"
    echo -e "[Unit]
Description=cloudreve
After=network.target
After=mysqld.service
Wants=network.target

[Service]
WorkingDirectory=$path
ExecStart=$path/cloudreve
Restart=always
RestartSec=3s
KillMode=mixed

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/cloudreve.service
systemctl daemon-reload
	_echo "安装完成" 1
	_echo "设置开机启动" 1
	systemctl enable cloudreve 2> /dev/null
	_echo "启动" 1
	systemctl start cloudreve
	sleep 1s
	user=$( systemctl status cloudreve |grep "管理员账号" | sed 's/^.*：//g')
	passwd=$(systemctl status cloudreve |grep "管理员密码" | sed 's/^.*：//g')
	if [[ -n "$user" ]]; then
	_echo "初始账号: $user" 1
	_echo "初始密码: $passwd" 1
	fi
fi

}
uninstall(){
    	_echo "开始卸载" 1
    read -p "卸载目录(默认:/etc/cloudreve): " path
    [[ -z "$path" ]] && path="/etc/cloudreve"
    	systemctl stop cloudreve
    	systemctl disable cloudreve 2> /dev/null
    	rm -rf "$path"
	rm -rf $(systemctl status cloudreve | grep "Loaded:" | sed 's/;.*$//g;s/^.*(//g')
    	_echo "卸载完成" 1
}
status(){
run=$(systemctl status cloudreve | grep " Active: " | grep -o "running")
pid=$(systemctl status cloudreve | grep "Main PID: " | grep -oE "[0-9]+")
}
start(){
	systemctl start cloudreve
	sleep 0.5s
	status
	if [[ -n $run ]]; then
		_echo "启动成功,进程PID: $pid" 1
	else
		_echo "启动失败" 0
	fi
}
restart(){
	systemctl restart cloudreve
	sleep 0.5s
	status
	if [[ -n $run ]]; then
		_echo "重启成功,进程PID: $pid" 1
	else
		_echo "重启失败" 0
	fi
}
stop(){
	systemctl stop cloudreve
	sleep 0.5s
	status
	if [[ -z $run ]]; then
		_echo "已关闭" 1
	fi
}
case $1 in
    install)
    install
    ;;
    uninstall)
    uninstall
    ;;
    start)
    start
    ;;
    restart)
    restart
    ;;
    stop)
    stop
    ;;
    status)
    status
    ;;
    *)
	_echo "$0 {start|restart|stop|status|install|uninstall}" 1
    ;;
esac

