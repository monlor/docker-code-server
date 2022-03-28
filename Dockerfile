FROM codercom/code-server:4.2.0

USER root

# 安装常用工具
RUN apt update && apt install -y build-essential vim dnsutils net-tools telnet golang python3 python3-pip openssh-server && \
    # python 工具
    pip3 install ydcv && \
    # k8s 工具
    curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x /usr/local/bin/kubectl && \
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # 时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone && \
    # 配置 openssh，这里需要固化 ssh server 的密钥
    mkdir -p /var/run/sshd && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config && \
    sed -i '/^exec/i echo "n" | ssh-keygen -q -t rsa -b 2048 -f /home/coder/.ssh/ssh_host_rsa_key -N "" || true' /usr/bin/entrypoint.sh && \ 
    sed -i '/^exec/i echo "n" | ssh-keygen -q -t ecdsa -f /home/coder/.ssh/ssh_host_ecdsa_key -N "" || true' /usr/bin/entrypoint.sh && \ 
    sed -i '/^exec/i echo "n" | ssh-keygen -t dsa -f /home/coder/.ssh/ssh_host_ed25519_key -N "" || true' /usr/bin/entrypoint.sh && \ 
    sed -i '/^exec/i sudo dumb-init /usr/sbin/sshd -D &' /usr/bin/entrypoint.sh && \
    # 修改用户默认 shell
    usermod -s /bin/zsh coder && \
    echo "root 用户命令执行完毕..."

USER coder

# 安装 brew
RUN echo -e '\n' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  && \
    eval $(/home/linuxbrew/.linuxbrew/Homebrew/bin/brew shellenv) && \
    # 安装 oh-my-zsh
    echo 'y' | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    # brew 环境变量
    echo 'eval $(/home/linuxbrew/.linuxbrew/Homebrew/bin/brew shellenv) #ckbrew' >> ~/.zshrc && \
    # 安装 brew 工具
    brew tap monlor/taps && brew install monlor/taps/gits && \
    echo "coder 用户命令执行完毕..."
