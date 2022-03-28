FROM codercom/code-server:4.2.0

USER root

# 安装常用工具
RUN apt update && apt install -y build-essential vim dnsutils net-tools telnet golang python3 openssh-server && \
    # k8s 工具
    curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x /usr/local/bin/kubectl && \
    # 时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone && \
    # 配置 openssh
    mkdir -p /var/run/sshd && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    sed -e '/^exec/i exec dumb-init /usr/sbin/sshd -D &' /usr/bin/entrypoint.sh && \
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
