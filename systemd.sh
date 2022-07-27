#!/usr/bin/bash
# echo "systemd管理脚本"

























echo "1.添加"
echo "2.修改"
echo "3.删除"
echo "4.管理状态"
read -p "序号: " x
[[ -z ${x} ]] && exit
if [[ ${x} == "1" ]];then
    echo "选择了添加"
fi

if [[ ${x} == "2" ]];then
    echo "选择了修改"
fi

if [[ ${x} == "3" ]];then
    echo "选择了删除"
fi

if [[ ${x} == "4" ]];then
    echo "管理"
fi
