#!/bin/bash
blue="\033[34m\033[01m"
green="\033[32m\033[01m"
yellow="\033[33m\033[01m"
red="\033[31m\033[01m"
Font="\033[0m"
IFS=$'\n'

#安装
install(){
    # 获取最新版本
    frps_url=$(curl -s https://github.com/fatedier/frp/releases.atom | grep '<link rel="alternate" type="text\/html" href=' | sed 's/^.*href="//g' | sed 's/"\/>//g' | head -1)
    # 最新版本
    frps_update_version=${frps_url##*/v}
    # 架构
    Arch="linux_amd64"
    # 版本
    frps_version="${frps_update_version}"
    # 获取新版本失败 退出
    [[ -z ${frps_update_version} ]] && exit 0
    url="https://github.com/fatedier/frp/releases/download/v${frps_version}/frp_${frps_version}_${Arch}.tar.gz"
    
    
    
    [[ ! -d "mkdir /etc/frpc" ]] && mkdir /etc/frpc
    cd /etc/frpc
    wget -O "${frps_version}.tar.gz" $url
	tar zxf "${frps_version}.tar.gz"
	cp -f ./frp_${frps_version}_linux_amd64/frpc ./
	rm -rf "frp_${frps_version}_linux_amd64" "${frps_version}.tar.gz"
	chmod +x /etc/frpc/frpc
echo -e "[Unit]
Description=Frpc
After=network.target

[Service]
User=root
Restart=always
RestartSec=3s
ExecStart=/etc/frpc/frpc -c /etc/frpc/frpc.ini


[Install]
WantedBy=multi-user.target" > /lib/systemd/system/frpc.service
systemctl daemon-reload
systemctl enable frpc
}
#卸载
uninstall(){
	systemctl stop frpc
	systemctl disable frpc
	systemctl daemon-reload
	rm -rf /etc/frpc
	rm -rf /lib/systemd/system/frpc.service
}
# 删除配置
frpc_edit_del(){
    [[ ! -d "/etc/frpc/conf" ]] && exit 0
    for i in `ls /etc/frpc/conf` ; do
        echo $i
    done
    read -p "要删除的配置:" x
    rm -rf "/etc/frpc/conf/${x}"
    
}
# 添加配置
frpc_edit_add(){
    [[ ! -d /etc/frpc/conf ]] && mkdir -p /etc/frpc/conf
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
        [[ -f "/etc/frpc/conf/${name}" ]] && echo -e "$red[INFO]$Font 配置已存在" && exit 0
echo -e "[${name}]
type = tcp
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${server_port}" > /etc/frpc/conf/${name}
    fi
    if [[ $t = "2" ]]; then
        read -p "配置名称:" name
        read -p "本地IP:" local_ip
        read -p "端口:" local_port
        read -p "域名:" custom_domains
        [[ -f "/etc/frpc/conf/${name}" ]] && echo -e "$red[INFO]$Font 配置已存在" && exit 0
echo -e "[${name}]
type = http
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${custom_domains}" > /etc/frpc/conf/${name}
    fi
    if [[ $t = "3" ]]; then
        read -p "配置名称:" name
        read -p "本地IP:" local_ip
        read -p "端口:" local_port
        read -p "域名:" custom_domains
        read -p "证书路径:" plugin_crt_path
        read -p "密钥路径:" plugin_key_path
        [[ -f "/etc/frpc/conf/${name}" ]] && echo -e "$red[INFO]$Font 配置已存在" && exit 0
        
echo -e "[${name}]
type = https
custom_domains = ${custom_domains}
plugin = https2http
plugin_local_addr = ${local_ip}:${local_port}
plugin_crt_path = ${plugin_crt_path}
plugin_key_path = ${plugin_key_path}
plugin_host_header_rewrite = 127.0.0.1
plugin_header_X-From-Where = frp" > /etc/frpc/conf/${name}
    fi
    if [[ $t = "4" ]]; then
        read -p "服务器IP:" server_ip
        read -p "连接端口:"  server_port
        read -p "TOKEN:"  server_token
echo -e "[common]
server_addr = ${server_ip}
server_port = ${server_port}
token = ${server_token}" > /etc/frpc/server
       
    fi
    
}
# 启动
frpc_start(){
    systemctl start frpc
    sleep 0.5s
    if [[ -n $(systemctl status frpc | grep "Active" | grep "running") ]]; then
    	echo -e "$green[INFO]$Font 已启动"
    	else
    	echo -e "$red[INFO]$Font 启动失败"
    fi
}
# 关闭
frpc_stop(){
    systemctl stop frpc
    sleep 0.5s
    if [[ -z $(systemctl status frpc | grep "Active" | grep "running") ]]; then
    	echo -e "$green[INFO]$Font 已关闭"
    fi

}
# 重启
frpc_restart(){
    systemctl restart frpc
    sleep 0.5s
    if [[ -n $(systemctl status frpc | grep "Active" | grep "running")  ]]; then
    	echo -e "$green[INFO]$Font 已重启"
    	else
    	echo -e "$red[INFO]$Font 未能重启,进程已关闭"
    fi

    
}
frpc_pid(){
if [[ -n $(systemctl status frpc | grep "Active" | grep "running") ]]; then
	echo -e "$green[INFO]$Font 运行中"
	echo -e "进程PID：$(systemctl status frpc |grep "Main PID:"| cut -d " " -f4)"
	else
	echo -e "$red[INFO]$Font 未运行"
fi
}
# 合并配置
frpc_edit_m(){
    [[ ! -f /etc/frpc/server ]] && echo "找不到服务器配置文件" && exit 0

    server_info=`cat /etc/frpc/server`"\n"
    echo -e "${server_info}" > /etc/frpc/frpc.ini
    for i in `ls /etc/frpc/conf` ; do
    
        info=`cat /etc/frpc/conf/$i`"\n"
        echo -e "${info}" >> /etc/frpc/frpc.ini
        
    done

    
}

home(){
    echo -e $green'  1. '$Font'安装'
    echo -e $green'  2. '$Font'卸载'
    echo "———————————————————————————"
    echo -e $green'  3. '$Font'启动'
    echo -e $green'  4. '$Font'停止'
    echo -e $green'  5. '$Font'重启'
    echo "———————————————————————————"
    echo -e $green'  6. '$Font'添加配置'
    echo -e $green'  7. '$Font'合并配置'
    echo -e $green'  8. '$Font'删除配置'
    frpc_pid
    read -p "选项:" x
    [[ $x == "1" ]] && install
    [[ $x == "2" ]] && uninstall
    [[ $x == "3" ]] && frpc_start
    [[ $x == "4" ]] && frpc_stop
    [[ $x == "5" ]] && frpc_restart
    [[ $x == "6" ]] && frpc_edit_add
    [[ $x == "7" ]] && frpc_edit_m
    [[ $x == "8" ]] && frpc_edit_del
    
}
home
