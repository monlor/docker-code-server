FROM monlor/archlinux-base:main

LABEL MAINTAINER="me@monlor.com"

EXPOSE 8080 22

VOLUME [ "/home/coder" ]

ENV HOST="code-server"
ENV USER=coder

# Allow users to have scripts run on container startup to prepare workspace.
# https://github.com/coder/code-server/issues/5177
ENV ENTRYPOINTD=${HOME}/entrypoint.d

# 安装root必须程序
RUN pacman -Syu --needed --noconfirm && pacman -S --needed --noconfirm fakeroot sudo base-devel vi vim yay git zsh dnsutils net-tools inetutils iputils cronie oh-my-zsh-git zsh-autosuggestions zsh-syntax-highlighting openssh bat trash-cli openconnect oath-toolkit go-yq tree jq zip unzip autojump upx neofetch ttf-jetbrains-mono rsync clash python3 python-pip python-pipx nodejs npm go mariadb-clients mycli && \
  # npm 工具
  npm install --global yarn tyarn commitizen git-cz && \
  # pip 工具
  pipx install ydcv && \
  # 配置 openssh，这里需要固化 ssh server 的密钥
  mkdir -p /var/run/sshd && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
  echo 'HostKey /home/coder/.ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config && \
  # add user
  useradd --create-home --no-log-init --shell /bin/zsh coder && \
  echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd && \
  mkdir -p /workspace && chown coder:coder /workspace && \
  # fixuid
  curl -fsSL "https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-amd64.tar.gz" | tar -C /usr/local/bin -xzf - && \
  chown root:root /usr/local/bin/fixuid && \
  chmod 4755 /usr/local/bin/fixuid && \
  mkdir -p /etc/fixuid && \
  printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

# 安装coder必须操作
USER coder 

RUN yay -S --save --noconfirm code-server frpc && \
  # fix
  cp -rf /usr/share/oh-my-zsh/zshrc ~/.zshrc && \
  # 添加回收站定时清理任务
  echo "@daily $(which trash-empty) 30" | crontab - 

# 下面是可能经常修改会影响缓存的部分，放在最后

# 用户root

USER root

ENV PACMAN_PKG="buildkit jdk11-openjdk age fzf helmfile kubectl-bin helm k9s kubectx vault sops docker-compose maven kustomize"

ENV NPM_PKG="wrangler hexo"

RUN pacman -S --needed --noconfirm ${PACMAN_PKG} && \
  # npm 工具
  npm install --global ${NPM_PKG} && \
  # 安装 easyoc，easy openconnect
  curl -#fSLo /usr/local/bin/easyoc https://github.com/monlor/shell-utils/raw/master/easyoc && \
  # 清理缓存
  pacman --noconfirm -Scc && \
  npm cache clean --force && \
  rm -rf /tmp/cache

COPY ./start.sh /opt/start.sh

COPY ./entrypoint.sh /usr/bin/entrypoint.sh

RUN chmod +x /usr/bin/entrypoint.sh /opt/start.sh /usr/local/bin/*

# 用户coder

USER coder 

ENV AUR_PKG="kubecm-git kind docker-slim docker-cli-bin"

RUN yay -S --save --noconfirm ${AUR_PKG} && \
  # helm plugin 
  helm plugin install https://github.com/databus23/helm-diff && \
  helm plugin install https://github.com/jkroepke/helm-secrets && \
  # 清理缓存
  yay --noconfirm -Scc && \
  sudo rm -rf ~/.cache/* ~/go

WORKDIR /workspace

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]