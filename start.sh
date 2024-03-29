#!/bin/bash

# code-server: PASSWORD
# clash: CLASH_SUB_URL
# ydcv环境变量：YDCV_YOUDAO_APPID YDCV_YOUDAO_APPSEC
# docker dind: DOCKER_DIND_HOST DOCKER_DIND_CERT_PATH

# 启动定时任务
echo "启动定时任务守护程序 ..."
sudo dumb-init /usr/sbin/crond

# 配置启动 openssh server
echo "n" | ssh-keygen -q -t rsa -b 2048 -f /home/coder/.ssh/ssh_host_rsa_key -N "" || true
echo "n" | ssh-keygen -q -t ecdsa -f /home/coder/.ssh/ssh_host_ecdsa_key -N "" || true
echo "n" | ssh-keygen -t dsa -f /home/coder/.ssh/ssh_host_ed25519_key -N "" || true
sudo dumb-init /usr/sbin/sshd -D &

# 启动 npc
if [ -n "${NPS_SERVER}" -a -n "${NPS_KEY}" ]; then
    echo "启动内网穿透 npc ..."
    nohup npc -server=${NPS_SERVER} -vkey=${NPS_KEY} -type=${NPS_TYPE:-tcp} &
fi

# 启动 clash
if [ -n "${CLASH_SUB_URL}" ]; then
    echo "配置 clash ..."
    if [ ! -d "${HOME}/.config/clash" ]; then
        mkdir -p ${HOME}/.config/clash
    fi
    curl -#fSLo ${HOME}/.config/clash/config.yaml ${CLASH_SUB_URL}
fi

# oh-my-zsh


# 自定义环境变量
echo "写入 zsh 环境变量配置 ..."
cat > ${HOME}/.zshrc <<-EOF
# oh-my-zsh
ZSH=/usr/share/oh-my-zsh/
ZSH_THEME="robbyrussell"
plugins=(git)
ZSH_CACHE_DIR=\$HOME/.cache/oh-my-zsh
if [[ ! -d \$ZSH_CACHE_DIR ]]; then
  mkdir -p \$ZSH_CACHE_DIR
fi
source \$ZSH/oh-my-zsh.sh

# env
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
export GOROOT=/usr/local/go
export GOPATH=\${HOME}/golang
export PATH=\$GOPATH/bin:\$GOROOT/bin:\$HOME/.local/bin:\$PATH:/usr/local/bin:/usr/sbin
# history show timeline
export HIST_STAMPS="yyyy-mm-dd"
# default editor
export VISUAL=vim
export EDITOR="\$VISUAL"
# bat
export BAT_THEME="GitHub"
# docker in docker
export DOCKER_HOST=tcp://${DOCKER_DIND_HOST:-docker}:2376
export DOCKER_CERT_PATH=${DOCKER_DIND_CERT_PATH:-"/certs/client"}
export DOCKER_TLS_VERIFY=1
# ydcv
export YDCV_YOUDAO_APPID=${YDCV_YOUDAO_APPID}
export YDCV_YOUDAO_APPSEC=${YDCV_YOUDAO_APPSEC}

# alias
alias upxx="upx --lzma --ultra-brute"
alias cp="cp -i"
alias rm="trash"
alias k="kubectl"
alias cat="batcat"
alias ping="ping"
alias init-git-cz="commitizen init git-cz --save-dev --save-exact"

# plugin
[[ -s /etc/profile.d/autojump.zsh ]] && source /etc/profile.d/autojump.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# completion
which helm &> /dev/null && source <(helm completion zsh)
which kubectl &> /dev/null && source <(kubectl completion zsh)
which k9s &> /dev/null && source <(k9s completion zsh)

setproxy() {
    sudo kill -15 `pidof clash` &> /dev/null
    clash &> /dev/null &
    export HTTP_PROXY=${HTTP_PROXY_ADDR:-127.0.0.1:7890}
    export HTTPS_PROXY=${HTTP_PROXY_ADDR:-127.0.0.1:7890}
    export NO_PROXY=localhost,127.0.0.1,.example.com
}

unsetproxy() {
    sudo kill -15 \`pidof clash\` &> /dev/null
    unset HTTP_PROXY
    
    unset HTTPS_PROXY
}

# load user zshrc
[ -f ${HOME}/.zshrc.user ] && source ${HOME}/.zshrc.user
EOF