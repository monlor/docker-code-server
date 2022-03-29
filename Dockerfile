FROM codercom/code-server:4.2.0

ENV NPS_VERSION="v0.26.10"

ENV CLASH_VERSION="v1.10.0"

ENV ZSH_COMPDUMP="/home/coder/.zcompdump"

COPY ./start.sh /opt/start.sh

COPY ./extensions /opt/extensions

USER root

# 安装常用工具
RUN apt update && apt install -y build-essential cron vim dnsutils net-tools telnet golang python3 python3-pip openssh-server openconnect && \
    # python 工具
    pip3 install ydcv && \
    # k8s 工具
    curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x /usr/local/bin/kubectl && \
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # nps 客户端
    mkdir /tmp/npc && \
    curl -Lo /tmp/npc/linux_amd64_client.tar.gz https://github.com/ehang-io/nps/releases/download/${NPS_VERSION}/linux_amd64_client.tar.gz && \
    tar zxvf /tmp/npc/linux_amd64_client.tar.gz -C /tmp/npc && \
    /tmp/npc/npc install && rm -rf /tmp/npc && \
    # clash 客户端
    curl -Lo /tmp/clash-linux-amd64.gz https://github.com/Dreamacro/clash/releases/download/${CLASH_VERSION}/clash-linux-amd64-v1.10.0.gz && \
    cat /tmp/clash-linux-amd64.gz | gzip -d > /usr/local/bin/clash && \
    chmod +x /usr/local/bin/clash && rm -rf /tmp/clash-linux-amd64.gz && \
    # 时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone && \
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

# 安装 brew
RUN echo -e '\n' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  && \
    eval $(/home/linuxbrew/.linuxbrew/Homebrew/bin/brew shellenv) && \
    # 安装 brew 工具
    brew tap monlor/taps && brew install monlor/taps/gits && \
    echo "coder 用户命令执行完毕..."
