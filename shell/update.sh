#!/bin/bash
# 此脚本是本人在KC工作期间编写的程序一键更新脚本，由jenkins调用，习惯配置在sshoverPublish插件中用于直接更新个人定义的程序。
# 此脚本的使用前提是需要由一个jenkins的每日构建任务用来每天将最新的程序包推送到线上服务器特定目录，并在更新时一键替换。
# 此脚本分别替换jar包和前端，jar包使用supervisor监控管理，此脚本也基于此服务。
# 此脚本使用了变量标记和Array。

set -e

# 变量
timestamp=$(date +%Y.%m.%d'_'%H%M)
basePath=/path/to/app/dir
shiliWebFiles=/path/to/webfile/dir
pkgArray=("qili-auth.jar" "qili-gateway.jar" "qili-modules-job.jar" "qili-modules-system.jar" "shili-modules-api.jar")

# function：更新UI
updateUI() {
    # 判断士礼项目的nginx目录是否存在dist.old目录，将其删除
    if [ -d ${shiliWebFiles}/dist.old ]; then
            rm -rf ${shiliWebFiles}/dist.old
    fi
    # 判断士礼项目的nginx目录是否存在dist目录，存在将其改为dist.old来备份一个版本
    if [ -d ${shiliWebFiles}/dist ]; then
            /bin/mv ${shiliWebFiles}/dist ${shiliWebFiles}/dist.old
    fi
    # 解压每日构建的最新UI包到士礼nginx项目目录，解压后备份到${basePath}的backup目录并在名字中加上时间
    tar -xf ${basePath}/upload/dist.tgz -C ${shiliWebFiles}
    /bin/mv ${basePath}/upload/dist.tgz ${basePath}/backup/${timestamp}
    chown -R root:root ${shiliWebFiles}/dist
}

# function：更新pkgArray组内定义应用
updateService() {
    for pkgName in ${pkgArray[@]}; do
        # 停止服务
        supervisorctl stop ${pkgName}
        # 备份旧包
        if [ -e ${basePath}/online/${pkgName} ]; then
            /bin/mv ${basePath}/online/${pkgName} ${basePath}/backup/${timestamp}
        fi
        # 替换新包
        if [ -e ${basePath}/upload/${pkgName} ]; then
            /bin/mv ${basePath}/upload/${pkgName} ${basePath}/online
        fi
        supervisorctl start ${pkgName}
    done
}

# main
fileExist=true
for pn in ${pkgArray[@]}; do
    if [ ! -f ${basePath}/upload/${pn} ]; then
        fileExist=false
    fi
done

if [ ! -f ${basePath}/upload/dist.tgz ]; then
    fileExist=false
fi

if [ ${fileExist} = true ]; then
    mkdir -p ${basePath}/backup/${timestamp}
    updateService
    updateUI
else
    echo "[ ${basePath}/upload 内文件不全，请先检查该目录文件 ]"
    exit 1
fi
