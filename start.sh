#!/bin/bash

# ydcv环境变量：YDCV_YOUDAO_APPID YDCV_YOUDAO_APPSEC

set -e

# 配置启动 openssh server
echo "n" | ssh-keygen -q -t rsa -b 2048 -f /home/coder/.ssh/ssh_host_rsa_key -N "" || true
echo "n" | ssh-keygen -q -t ecdsa -f /home/coder/.ssh/ssh_host_ecdsa_key -N "" || true
echo "n" | ssh-keygen -t dsa -f /home/coder/.ssh/ssh_host_ed25519_key -N "" || true
sudo dumb-init /usr/sbin/sshd -D &

# 启动 npc
if [ -n "${NPS_SERVER}" -a -n "${NPS_KEY}" ]; then
    dumb-init npc -server=${NPS_SERVER} -vkey=${NPS_KEY} -type=${NPS_TYPE:-tcp} &
fi

if [ ! -d ${HOME}/.oh-my-zsh ]; then
    # 安装 oh-my-zsh
    echo 'y' | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # brew 环境变量
    echo 'eval $(/home/linuxbrew/.linuxbrew/Homebrew/bin/brew shellenv) #ckbrew' >> ${HOME}/.zshrc 
fi

