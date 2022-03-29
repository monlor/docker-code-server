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
    # brew 环境变量
    echo 'eval $(/home/linuxbrew/.linuxbrew/Homebrew/bin/brew shellenv) #ckbrew' >> ${HOME}/.zshrc 
    # 自定义环境变量
    cat >> ${HOME}/.zshrc <<-EOF
setproxy() {
    sudo killall clash &> /dev/null &
    sleep 1
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
fi

