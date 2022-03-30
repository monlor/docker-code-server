#!/bin/bash

# ydcv环境变量：YDCV_YOUDAO_APPID YDCV_YOUDAO_APPSEC

set -e

# 启动定时任务
sudo /usr/sbin/cron

# 配置启动 openssh server
echo "n" | ssh-keygen -q -t rsa -b 2048 -f /home/coder/.ssh/ssh_host_rsa_key -N "" || true
echo "n" | ssh-keygen -q -t ecdsa -f /home/coder/.ssh/ssh_host_ecdsa_key -N "" || true
echo "n" | ssh-keygen -t dsa -f /home/coder/.ssh/ssh_host_ed25519_key -N "" || true
sudo dumb-init /usr/sbin/sshd -D &

# 启动 npc
if [ -n "${NPS_SERVER}" -a -n "${NPS_KEY}" ]; then
    echo "配置 nps..."
    nohup npc -server=${NPS_SERVER} -vkey=${NPS_KEY} -type=${NPS_TYPE:-tcp} &
fi

# 启动 clash
if [ -n "${CLASH_SUB_URL}" ]; then
    echo "配置 clash..."
    if [ ! -d "${HOME}/.config/clash" ]; then
        mkdir -p ${HOME}/.config/clash
    fi
    curl -#Lo ${HOME}/.config/clash/config.yaml ${CLASH_SUB_URL}
fi

if [ ! -f ${HOME}/.oh-my-zsh/oh-my-zsh.sh ]; then
    echo "安装 oh-my-zsh ..."
    rm -rf ${HOME}/.oh-my-zsh
    # 安装 oh-my-zsh
    echo 'y' | sh -c "$(curl -fsSL https://github.do/https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 安装 zsh 插件
if [ ! -d ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
if [ ! -d ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi
if [ ! -d ${HOME}/.autojump ]; then
    cp -rf /tmp/autojump ${HOME}/.autojump
fi

# 自定义环境变量
cat > ${HOME}/.zshrc <<-\EOF
# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh
export PATH=$PATH:/usr/sbin:/sbin

# plugin
[[ -s ${HOME}/.autojump/etc/profile.d/autojump.sh ]] && source ${HOME}/.autojump/etc/profile.d/autojump.sh

# alias
alias upxx="upx --lzma --ultra-brute"
alias cp="cp -i"
alias rm="trash"

# completion
which helm &> /dev/null && source <(helm completion zsh)

# env
export GOPROXY=https://goproxy.io,direct
export GOPATH=~/golang
export GO111MODULE=auto
# history show timeline
export HIST_STAMPS="yyyy-mm-dd"

setproxy() {
    sudo killall clash &> /dev/null
    /usr/local/bin/clash &> /dev/null &
    export http_proxy=127.0.0.1:7890
    export https_proxy=127.0.0.1:7890
}

unsetproxy() {
    sudo killall clash
    unset http_proxy
    unset https_proxy
}
EOF