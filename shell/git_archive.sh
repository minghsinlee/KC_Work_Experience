# 此脚本为全量备份脚本，且来备份git仓库目录中的所有仓库与所有分支的代码

#!/bin/bash

gitRepo_Array=($(find /data/docker-compose/gitea/bind/gitea/git/repositories/ -maxdepth 2 -name "*.git"))
targetForder=/data/tempforder/gitbackup/archive
timestamp=$(date +%Y.%m.%d'_'%H%M)

for gitRepo in "${gitRepo_Array[@]}"; do
    gitname=$(echo ${gitRepo} | rev | cut -d "/" -f 1 | rev)
    mkdir -p ${targetForder}/${gitname}
    branch_Array=($(cat ${gitRepo}/info/refs | rev | cut -d "/" -f 1 | rev))
    for branch in ${branch_Array[@]}; do
        mkdir -p ${targetForder}/${gitname}/${branch}
        git clone -b ${branch} ${gitRepo} ${targetForder}/${gitname}/${branch}
    done
done

#打包
cd ${targetForder}/../
zip -r -9 ./zip/gitarchive${timestamp}.zip ./archive
#清理作业目录
rm -rf ${targetForder}/*
#rsync传输到特定服务器的目标目录供下载
sshpass -p "PASSWORD" rsync -ahPvz --bwlimit=200  -e "ssh -p 28332" ${targetForder}/../zip/gitarchive${timestamp}.zip root@SERVER_IP:/data/backup/gitarchive/
#删除旧包
rm -rf ${targetForder}/../zip/*
