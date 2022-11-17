# https://github.com/coder/code-server/releases
FROM codercom/code-server:4.8.3

LABEL author=monlor

ARG TARGETARCH

ENV HOST="code-server"

USER root

RUN apt update && apt install -y build-essential cron vim dnsutils net-tools iputils-ping iproute2 telnet bat trash-cli openconnect oathtool mariadb-client upx openssh-server python3 python3-pip nodejs npm age rsync tree jq zip fzf golang && \
    # python 工具
    ln -sf /usr/bin/python3 /usr/bin/python && \
    pip3 install ydcv mycli && \
    # npm 工具
    npm install --global yarn tyarn commitizen git-cz && \
    # 时区
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone && \
    # 配置 openssh，这里需要固化 ssh server 的密钥
    mkdir -p /var/run/sshd && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config && \
    echo 'HostKey /home/coder/.ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config && \
    sed -i '/^exec/i /opt/start.sh' /usr/bin/entrypoint.sh && \
    # 修改用户默认 shell
    usermod -s /bin/zsh coder 

# https://github.com/ehang-io/nps/releases
ENV NPS_VERSION="v0.26.10"
# https://github.com/Dreamacro/clash/releases
ENV CLASH_VERSION="v1.11.8"
# https://download.docker.com/linux/static/stable/x86_64/
ENV DOCKER_VERSION="20.10.17"
# https://github.com/docker-slim/docker-slim/releases
ENV DOCKER_SLIM_VERSION="1.37.6"
# https://github.com/helmfile/helmfile/releases
ENV HELMFILE_VERSION="0.145.2"
# https://github.com/mozilla/sops/releases
ENV SOPS_VERSION="v3.7.3"
# https://github.com/mikefarah/yq/releases
ENV YQ_VERSION="v4.25.2"
# https://github.com/kubernetes-sigs/kind/releases
ENV KIND_VERSION="v0.14.0"
# https://github.com/sunny0826/kubecm/releases
ENV KUBECM_VERSION="0.17.0"
# https://github.com/derailed/k9s/releases
ENV K9S_VERSION="v0.25.21"
# https://github.com/hashicorp/vault/releases
ENV VAULT_VERSION="1.11.0"
# https://github.com/ahmetb/kubectx/releases
ENV KUBECTX_VERSION="v0.9.4"

# 安装常用工具
RUN set -x && \
    if [ "${TARGETARCH}" = "amd64" ]; then TARGETARCH_A="x86_64"; else TARGETARCH_A=${TARGETARCH}; fi && \
    if [ "${TARGETARCH}" = "arm64" ]; then TARGETARCH_B="armv8"; else TARGETARCH_B=${TARGETARCH}; fi && \
    if [ "${TARGETARCH}" = "arm64" ]; then TARGETARCH_C="aarch64"; else TARGETARCH_C=${TARGETARCH}; fi && \
    # tailscale
    curl -fsSL https://tailscale.com/install.sh | sh && \
    # yq
    curl -#fSLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH} && \
    # k8s 工具
    curl -#fSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" && \
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    # k9s 
    curl -#fSLo /tmp/k9s_Linux_x86_64.tar.gz https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${TARGETARCH_A}.tar.gz && \
    tar zxvf /tmp/k9s_Linux_x86_64.tar.gz -C /usr/local/bin k9s && \
    # kubectx kubens kubecm
    curl -#fSLo /tmp/kubectx.tar.gz https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_${TARGETARCH_A}.tar.gz && \
    curl -#fSLo /tmp/kubens.tar.gz https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_${TARGETARCH_A}.tar.gz && \
    tar xzvf /tmp/kubectx.tar.gz -C /usr/local/bin kubectx && \
    tar xzvf /tmp/kubens.tar.gz -C /usr/local/bin kubens && \
    curl -#fSLo /tmp/kubecm.tar.gz https://github.com/sunny0826/kubecm/releases/download/v${KUBECM_VERSION}/kubecm_${KUBECM_VERSION}_Linux_${TARGETARCH_A}.tar.gz && \
    tar xzvf /tmp/kubecm.tar.gz -C /usr/local/bin kubecm && \
    # vault
    curl -#fSLo /tmp/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip && \
    unzip /tmp/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip -d /usr/local/bin && \
    # nps 客户端
    mkdir /tmp/npc && \
    curl -#fSLo /tmp/npc/linux_${TARGETARCH}_client.tar.gz https://github.com/ehang-io/nps/releases/download/${NPS_VERSION}/linux_${TARGETARCH}_client.tar.gz && \
    tar zxvf /tmp/npc/linux_${TARGETARCH}_client.tar.gz -C /tmp/npc && \
    /tmp/npc/npc install && \
    # clash 客户端
    curl -#fSLo /tmp/clash-linux-${TARGETARCH_B}.gz https://github.com/Dreamacro/clash/releases/download/${CLASH_VERSION}/clash-linux-${TARGETARCH_B}-${CLASH_VERSION}.gz && \
    cat /tmp/clash-linux-${TARGETARCH_B}.gz | gzip -d > /usr/local/bin/clash && \
    # 安装 docker 客户端
    curl -#fSLo /tmp/docker-${DOCKER_VERSION}.tgz https://download.docker.com/linux/static/stable/${TARGETARCH_C}/docker-${DOCKER_VERSION}.tgz && \
    tar xzvf /tmp/docker-${DOCKER_VERSION}.tgz --strip 1 -C /usr/local/bin docker/docker && \
    # 安装 kind
    curl -#fSLo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${TARGETARCH} && \
    # 安装 easyoc，easy openconnect
    curl -#fSLo /usr/local/bin/easyoc https://github.com/monlor/shell-utils/raw/master/easyoc && \
    # 安装 helmfile 
    curl -#fSLo /tmp/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz && \
    tar zxvf /tmp/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz -C /usr/local/bin helmfile && \
    # 安装 sops
    curl -#fSLo /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${TARGETARCH} && \
    # 授权，清理
    chmod +x /usr/local/bin/* && \
    rm -rf /tmp/* 

COPY ./start.sh /opt/start.sh

COPY ./extensions /opt/extensions

RUN chmod +x /opt/start.sh

USER coder

# autojump
RUN git clone https://github.com/joelthelion/autojump /tmp/autojump && \
    cd /tmp/autojump && SHELL=/bin/zsh ./install.py && cd - && rm -rf /tmp/autojump && \
    cp -rf ~/.autojump /tmp/autojump && \
    # 添加回收站定时清理任务
    echo "@daily $(which trash-empty) 30" | crontab -