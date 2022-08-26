FROM monlor/archlinux-base:main

LABEL MAINTAINER="me@monlor.com"

EXPOSE 8080 22

VOLUME [ "/home/coder", "/workspace" ]

ENV HOST="code-server"

ENV PACMAN_PKG="bat trash-cli openconnect oath-toolkit mariadb-clients python3 nodejs age rsync tree jq zip fzf go mycli ydcv tailscale go-yq kubectl helm helmfile k9s kubectx vault clash sops autojump upx neofetch ttf-jetbrains-mono"

ENV AUR_PKG="kubecm-git kind docker-slim lsyncd"

ENV NPM_PKG="wrangler hexo"

# https://download.docker.com/linux/static/stable/x86_64/
ENV DOCKER_VERSION="20.10.17"
# https://github.com/docker-slim/docker-slim/releases
ENV DOCKER_SLIM_VERSION="1.37.6"

# Allow users to have scripts run on container startup to prepare workspace.
# https://github.com/coder/code-server/issues/5177
ENV ENTRYPOINTD=${HOME}/entrypoint.d

COPY ./start.sh /opt/start.sh

COPY ./extensions /opt/extensions

COPY ./entrypoint.sh /usr/bin/entrypoint.sh

RUN pacman -Syy && pacman -S --needed --noconfirm fakeroot sudo base-devel vi vim yay git zsh dnsutils net-tools inetutils iputils cronie oh-my-zsh-git zsh-autosuggestions zsh-syntax-highlighting npm openssh ${PACMAN_PKG} && \
  # npm 工具
  npm install --global yarn tyarn commitizen git-cz ${NPM_PKG} && \
  # 安装 docker 客户端
  curl -#fSLo /tmp/docker-${DOCKER_VERSION}.tgz https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz && \
  tar xzvf /tmp/docker-${DOCKER_VERSION}.tgz --strip 1 -C /usr/local/bin docker/docker && \
  # 安装 docker-slim 客户端
  curl -#fSLo /tmp/dist_linux.tar.gz https://downloads.dockerslim.com/releases/${DOCKER_SLIM_VERSION}/dist_linux.tar.gz && \
  tar zxvf /tmp/dist_linux.tar.gz --strip 1 -C /usr/local/bin dist_linux/ && \
  # 安装 easyoc，easy openconnect
  curl -#fSLo /usr/local/bin/easyoc https://github.com/monlor/shell-utils/raw/master/easyoc && \
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
  printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml && \
  # chmod
  chmod +x /usr/bin/entrypoint.sh /opt/start.sh /usr/local/bin/* && \
  # 清理缓存
  pacman --noconfirm -Scc && \
  rm -rf /tmp/cache

# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER coder
ENV USER=coder

RUN yay -S --save --noconfirm code-server nps ${AUR_PKG} && \
  # fix
  cp -rf /usr/share/oh-my-zsh/zshrc ~/.zshrc && \
  # 添加回收站定时清理任务
  echo "@daily $(which trash-empty) 30" | crontab - && \
  # 清理缓存
  yay --noconfirm -Scc && \
  sudo rm -rf ~/.cache/* ~/go

WORKDIR /workspace

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]