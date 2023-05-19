# https://github.com/coder/code-server/releases/latest
FROM codercom/code-server:4.11.0

LABEL MAINTAINER="me@monlor.com"

EXPOSE 8080 22

VOLUME [ "/home/coder" ]

ARG TARGETARCH

ENV HOST="code-server"

USER root

# 初始化配置
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone && \
    # 修改用户默认 shell
    usermod -s /bin/zsh coder

# 安装常用工具
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt update && apt install -y build-essential cron vim dnsutils net-tools iputils-ping iproute2 telnet bat trash-cli openconnect oathtool mariadb-client upx openssh-server python3 python3-pip nodejs age rsync tree jq zip fzf && \
    # python 工具
    ln -sf /usr/bin/python3 /usr/bin/python && \
    pip3 install ydcv mycli && \
    # npm 工具
    npm install --global yarn tyarn commitizen git-cz hexo && \
    # 配置 openssh，这里需要固化 ssh server 的密钥
    mkdir -p /var/run/sshd && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config

# 安装oh-my-zsh
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git /usr/share/oh-my-zsh && \
    git clone https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh/plugins/zsh-syntax-highlighting

# 安装依赖工具
COPY ./install-tools.sh /opt/scripts/
RUN bash /opt/scripts/install-tools.sh 

# 添加start脚本
COPY ./start.sh /opt/
RUN chmod +x /opt/start.sh && sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh

USER coder