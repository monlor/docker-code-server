FROM codercom/code-server:4.4.0

LABEL author=monlor

ENV NPS_VERSION="v0.26.10"

ENV CLASH_VERSION="v1.10.0"

ENV DOCKER_VERSION="20.10.14"

ENV DOCKER_SLIM_VERSION="1.37.6"

ENV HELMFILE_VERSION="v0.144.0"

ENV SOPS_VERSION="v3.7.2"

ENV YQ_VERSION="v4.25.2"

ENV KIND_VERSION="v0.14.0"

ENV HOST="code-server"

COPY ./start.sh /opt/start.sh

COPY ./extensions /opt/extensions

USER root

# 安装常用工具
RUN apt update && apt install -y build-essential cron vim dnsutils net-tools iputils-ping iproute2 telnet bat trash-cli openconnect oathtool mariadb-client upx openssh-server golang python3 python3-pip nodejs npm age rsync tree jq zip && \
    # python 工具
    ln -sf /usr/bin/python3 /usr/bin/python && \
    pip3 install ydcv mycli && \
    # npm 工具
    npm install --global yarn tyarn commitizen git-cz && \
    # yq
    curl -#fsSLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 && \
    # k8s 工具
    curl -#fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # nps 客户端
    mkdir /tmp/npc && \
    curl -#fsSLo /tmp/npc/linux_amd64_client.tar.gz https://github.com/ehang-io/nps/releases/download/${NPS_VERSION}/linux_amd64_client.tar.gz && \
    tar zxvf /tmp/npc/linux_amd64_client.tar.gz -C /tmp/npc && \
    /tmp/npc/npc install && \
    # clash 客户端
    curl -#fsSLo /tmp/clash-linux-amd64.gz https://github.com/Dreamacro/clash/releases/download/${CLASH_VERSION}/clash-linux-amd64-v1.10.0.gz && \
    cat /tmp/clash-linux-amd64.gz | gzip -d > /usr/local/bin/clash && \
    # 安装 docker 客户端
    curl -#fSLo /tmp/docker-${DOCKER_VERSION}.tgz https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz && \
    tar xzvf /tmp/docker-${DOCKER_VERSION}.tgz --strip 1 -C /usr/local/bin docker/docker && \
    # 安装 kind
    curl -#fSLo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64 && \
    # 安装 docker-slim 客户端
    curl -#fSLo /tmp/dist_linux.tar.gz https://downloads.dockerslim.com/releases/${DOCKER_SLIM_VERSION}/dist_linux.tar.gz && \
    tar zxvf /tmp/dist_linux.tar.gz --strip 1 -C /usr/local/bin dist_linux/ && \
    # 安装 easyoc，easy openconnect
    curl -#fsSLo /usr/local/bin/easyoc https://github.com/monlor/shell-utils/raw/master/easyoc && \
    # 安装 helmfile 
    curl -#fsSLo /usr/local/bin/helmfile https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64 && \
    # 安装 sops
    curl -#fsSLo /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64 && \
    # 时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone && \
    # 授权，清理
    chmod +x /usr/local/bin/* && \
    rm -rf /tmp/* && \
    # 配置 openssh，这里需要固化 ssh server 的密钥
    mkdir -p /var/run/sshd && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config && \
    chmod +x /opt/start.sh && sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh && \
    # 修改用户默认 shell
    usermod -s /bin/zsh coder && \
    echo "root 用户命令执行完毕..."

USER coder

# autojump
RUN git clone https://github.com/joelthelion/autojump /tmp/autojump && \
    cd /tmp/autojump && SHELL=/bin/zsh ./install.py && cd - && rm -rf /tmp/autojump && \
    cp -rf ~/.autojump /tmp/autojump