#!/usr/bin/env bash

install_path="/etc/frpc/"

_echo(){
	green="\033[32m\033[01m"
	red="\033[31m\033[01m"
	Font="\033[0m"
	if [[ $2 == 1 ]]; then
	    echo -e "$green[信息]$Font $1"
	fi
	if [[ $2 == 0 ]]; then
	    echo -e "$red[错误]$Font $1"
	fi
}
install(){
	version_info=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest)
	version=$(grep "tag_name" <<< "$version_info" | sed 's/tag_name//g;s/"//g;s/ //g;s/://g;s/,//g')
	download_url=$(grep "browser_download_url" <<< "$version_info" | sed 's/browser_download_url//g;s/"//g;s/ //g;s/://g;s/,//g;s/\/\//:\/\//g' | grep "linux_amd64")

	if [[ -z "$version" ]]; then
	_echo "获取版本失败" 0
	exit
	else
	[[ ! -d "${install_path}" ]] && mkdir "${install_path}"
	rm -rf ${install_path}*
	_echo "最新版本: $version" 1
	_echo "开始下载..." 1
	wget -q "${download_url}" -O ${install_path}frps.tar.gz
	tar zxf ${install_path}frps.tar.gz -C ${install_path} > /dev/null
	mv ${install_path}/frp_*/frpc ${install_path}
	chmod +x ${install_path}frpc
	rm -rf ${install_path}frp_* ${install_path}frps.tar.gz
	_echo "下载完成" 1
	fi
	
	echo -e "[Unit]
Description=Frpc
After=network.target

[Service]
User=root
Restart=always
RestartSec=3s
ExecStart=${install_path}frpc -c ${install_path}frpc.ini

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/frpc.service
systemctl daemon-reload
_echo "设置开机启动" 1
systemctl enable frpc
_echo "安装完成" 1
}
#卸载
uninstall(){
	_echo "停止frpc" 1
	systemctl stop frpc
	_echo "取消开机启动" 1
	systemctl disable frpc
	systemctl daemon-reload
	_echo "删除配置文件" 1
	rm -rf ${install_path}
	rm -rf /lib/systemd/system/frpc.service
	_echo "卸载完成" 1
}

# 启动
start(){
systemctl start frpc
sleep 0.5s
if [[ -n $(systemctl status frpc | grep "Active" | grep "running") ]]; then
	_echo "已启动" 1
	else
	_echo "启动失败" 0
fi

}
# 停止
stop(){
systemctl stop frpc
sleep 0.5s
if [[ -z $(systemctl status frpc | grep "Active" | grep "running") ]]; then
	_echo "已关闭" 1
fi

}
# 重启
restart(){
systemctl restart frpc
sleep 0.5s
if [[ -n $(systemctl status frpc | grep "Active" | grep "running")  ]]; then
	_echo "已重启" 1
	else
	_echo "未能重启,进程已关闭" 0
fi
}
# 添加配置
frpc_ini_add(){
    [[ ! -d ${install_path}conf ]] && mkdir -p ${install_path}conf
    echo -e $green'  1. '$Font'TCP'
    echo -e $green'  2. '$Font'HTTP'
    echo -e $green'  3. '$Font'HTTPS'
    echo -e $green'  4. '$Font'设置服务器信息'
    read -p "类型:" t
    if [[ ${t} = "1" ]]; then
        read -p "配置名称:" name
        read -p "本地IP:" local_ip
        read -p "端口:" local_port
        read -p "远程端口:" server_port
        [[ -f "${install_path}conf/${name}" ]] && echo -e "$red[INFO]$Font 配置已存在" && exit 0
echo -e "[${name}]
type = tcp
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${server_port}" > ${install_path}conf/${name}
    fi
    if [[ $t = "2" ]]; then
        read -p "配置名称:" name
        read -p "本地IP:" local_ip
        read -p "端口:" local_port
        read -p "域名:" custom_domains
        [[ -f "${install_path}conf/${name}" ]] && echo -e "$red[INFO]$Font 配置已存在" && exit 0
echo -e "[${name}]
type = http
local_ip = ${local_ip}
local_port = ${local_port}
custom_domains = ${custom_domains}" > ${install_path}conf/${name}
    fi
    if [[ $t = "3" ]]; then
        read -p "配置名称:" name
        read -p "本地IP:" local_ip
        read -p "端口:" local_port
        read -p "域名:" custom_domains
        read -p "证书路径:" plugin_crt_path
        read -p "密钥路径:" plugin_key_path
        [[ -f "${install_path}conf/${name}" ]] && echo -e "$red[INFO]$Font 配置已存在" && exit 0
        
echo -e "[${name}]
type = https
custom_domains = ${custom_domains}
plugin = https2http
plugin_local_addr = ${local_ip}:${local_port}
plugin_crt_path = ${plugin_crt_path}
plugin_key_path = ${plugin_key_path}
plugin_host_header_rewrite = 127.0.0.1
plugin_header_X-From-Where = frp" > ${install_path}conf/${name}
    fi
    if [[ $t = "4" ]]; then
        read -p "服务器IP:" server_ip
        read -p "连接端口:"  server_port
        read -p "TOKEN:"  server_token
echo -e "[common]
server_addr=${server_ip}
server_port=${server_port}
token=${server_token}" > ${install_path}server
       
    fi
    
}
# 合并配置
frpc_ini_m(){
    [[ ! -f ${install_path}server ]] && echo "找不到服务器配置文件" && exit 0

    server_info=`cat ${install_path}server`"\n"
    echo -e "${server_info}" > ${install_path}frpc.ini
    for i in `ls ${install_path}conf` ; do
    
        info=`cat ${install_path}conf/$i`"\n"
        echo -e "${info}" >> ${install_path}frpc.ini
        
    done
}
# 查看配置
frpc_ini_r(){
    [[ ! -f ${install_path}server ]] && echo "找不到服务器配置文件" && exit 0
	echo  "———————————————————————————"
	ip=$(grep "server_addr" ${install_path}server | cut -d "=" -f 2)
	port=$(grep "server_port" ${install_path}server | cut -d "=" -f 2)
	token=$(grep "token" ${install_path}server | cut -d "=" -f 2)
	echo "服务器: $ip		服务器端口: $port		token: $token"
    for i in `ls ${install_path}conf` ; do
    
	type=$(grep "type" ${install_path}conf/$i | cut -d "=" -f 2)
	local_port=$(grep "local_port" ${install_path}conf/$i | cut -d "=" -f 2)
	echo "名称: $i			类型: $type			本地端口: $local_port"
        
    done
}
# 删除配置
frpc_ini_d(){
	[[ ! -d "${install_path}conf" ]] && echo "配置目录不存在" && exit
	for i in `ls ${install_path}conf` ; do
	    echo "$i"
	done
	read -p "要删除的名称: " x
	[[ -z $x ]] && echo "退出" && exit
	rm -rf "${install_path}conf/$x"
}

echo "	000.安装"
echo "	111.卸载"
echo "	01.启动"
echo "	02.停止"
echo "	03.重启"
echo "	08.添加配置"
echo "	09.合并配置"
echo "	10.查看配置"
echo "	11.删除配置"
read -p "序号: " x
if [[ "$x" == "000" ]]; then
	install
fi
if [[ "$x" == "111" ]]; then
	uninstall
fi
if [[ "$x" == "01" ]]; then
	start
fi
if [[ "$x" == "02" ]]; then
	stop
fi
if [[ "$x" == "03" ]]; then
	restart
fi
if [[ "$x" == "08" ]]; then
	frpc_ini_add
fi
if [[ "$x" == "09" ]]; then
	frpc_ini_m
fi
if [[ "$x" == "10" ]]; then
	frpc_ini_r
fi
if [[ "$x" == "11" ]]; then
	frpc_ini_d
fi
# install

