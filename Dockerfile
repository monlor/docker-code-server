FROM codercom/code-server:4.2.0

# 安装 brew
RUN echo -e '\n' | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  && \
    eval $(/home/linuxbrew/.linuxbrew/Homebrew/bin/brew shellenv) && \
    # brew 国内源
    cd "$(brew --repo)" && git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git && \
    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core" && git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git && \
    # 安装 oh-my-zsh
    echo 'y' | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 
    # brew 环境变量
    echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/linuxbrew-bottles/bottles #ckbrew' >> ~/.zshrc && \
    echo 'eval $(/home/linuxbrew/.linuxbrew/Homebrew/bin/brew shellenv) #ckbrew' >> ~/.zshrc && \
    # 安装 code-server 插件
    # code-server --install-extension ms-python.python golang.Go eamodio.gitlens ms-kubernetes-tools.vscode-kubernetes-tools ms-azuretools.vscode-docker vscode-icons-team.vscode-icons formulahendry.auto-close-tag formulahendry.auto-close-tag formulahendry.auto-close-tag tumido.crd-snippets zhanghua.vscodium-language-pack-zh-cn

USER root

# 安装常用工具
RUN apt update && apt install -y vim dnsutils net-tools telnet golang python3 && \
    # k8s 工具
    curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

USER coder

 