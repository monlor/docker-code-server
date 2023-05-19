#!/bin/bash

set -eux

TARGET_PATH=/usr/local/bin
TEMP_DIR=`mktemp -d`

# https://github.com/ehang-io/nps/releases/latest
NPS_VERSION="v0.26.10"
# https://github.com/Dreamacro/clash/releases/latest
CLASH_VERSION="v1.14.0"
# https://download.docker.com/linux/static/stable/x86_64/
DOCKER_VERSION="23.0.2"
# https://github.com/helmfile/helmfile/releases/latest
HELMFILE_VERSION="0.152.0"
# https://github.com/mozilla/sops/releases/latest
SOPS_VERSION="v3.7.3"
# https://github.com/mikefarah/yq/releases/latest
YQ_VERSION="v4.33.2"
# https://github.com/kubernetes-sigs/kind/releases/latest
KIND_VERSION="v0.18.0"
# https://github.com/sunny0826/kubecm/releases/latest
KUBECM_VERSION="0.22.0"
# https://github.com/derailed/k9s/releases/latest
K9S_VERSION="v0.27.3"
# https://github.com/hashicorp/vault/releases/latest
VAULT_VERSION="1.13.1"
# https://github.com/ahmetb/kubectx/releases/latest
KUBECTX_VERSION="v0.9.4"
# https://go.dev/doc/install
GOLANG_VERSION="1.20.2"
# https://github.com/argoproj/argo-cd/releases/latest
ARGOCD_VERSION="v2.6.7"

# TARGETARCH=arm64|amd64

# yq
curl -#fSLo ${TARGET_PATH}/yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}
# k8s 工具
curl -#fSLo ${TARGET_PATH}/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl"
# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# k9s 
curl -#fSLo ${TEMP_DIR}/k9s.tar.gz https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz
tar -zxf ${TEMP_DIR}/k9s.tar.gz -C ${TARGET_PATH} k9s
# kubectx kubens kubecm
if [ ${TARGETARCH} = "amd64" ]; then
  KUBECTX_ARCH=x86_64
elif [ ${TARGETARCH} = "arm64" ]; then
  KUBECTX_ARCH=arm64
fi
curl -#fSLo ${TEMP_DIR}/kubens.tar.gz https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_${KUBECTX_ARCH}.tar.gz
curl -#fSLo ${TEMP_DIR}/kubectx.tar.gz https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_${KUBECTX_ARCH}.tar.gz
curl -#fSLo ${TEMP_DIR}/kubecm.tar.gz https://github.com/sunny0826/kubecm/releases/download/v${KUBECM_VERSION}/kubecm_v${KUBECM_VERSION}_Linux_${KUBECTX_ARCH}.tar.gz
tar -zxf ${TEMP_DIR}/kubens.tar.gz -C ${TARGET_PATH} kubens
tar -zxf ${TEMP_DIR}/kubectx.tar.gz -C ${TARGET_PATH} kubectx
tar -zxf ${TEMP_DIR}/kubecm.tar.gz -C ${TARGET_PATH} kubecm
# vault
curl -#fSLo ${TEMP_DIR}/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip
unzip ${TEMP_DIR}/vault_${VAULT_VERSION}_linux_${TARGETARCH}.zip -d ${TARGET_PATH}
# nps 客户端
mkdir ${TEMP_DIR}/npc
curl -#fSLo ${TEMP_DIR}/npc/linux_${TARGETARCH}_client.tar.gz https://github.com/ehang-io/nps/releases/download/${NPS_VERSION}/linux_${TARGETARCH}_client.tar.gz
tar -zxf ${TEMP_DIR}/npc/linux_${TARGETARCH}_client.tar.gz -C ${TEMP_DIR}/npc
${TEMP_DIR}/npc/npc install
# clash 客户端
curl -#fSLo ${TEMP_DIR}/clash-linux-${TARGETARCH}.gz https://github.com/Dreamacro/clash/releases/download/${CLASH_VERSION}/clash-linux-${TARGETARCH}-${CLASH_VERSION}.gz
cat ${TEMP_DIR}/clash-linux-${TARGETARCH}.gz | gzip -d > ${TARGET_PATH}/clash
# 安装 docker 客户端
if [ ${TARGETARCH} = "amd64" ]; then
  DOCKER_ARCH=x86_64
elif [ ${TARGETARCH} = "arm64" ]; then
  DOCKER_ARCH=aarch64
fi
curl -#fSLo ${TEMP_DIR}/docker-${DOCKER_VERSION}.tgz https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz
tar -zxf ${TEMP_DIR}/docker-${DOCKER_VERSION}.tgz --strip 1 -C ${TARGET_PATH} docker/docker
# 安装 kind
curl -#fSLo ${TARGET_PATH}/kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${TARGETARCH}
# 安装 easyoc，easy openconnect
curl -#fSLo ${TARGET_PATH}/easyoc https://github.com/monlor/shell-utils/raw/master/easyoc
# 安装 helmfile 
curl -#fSLo ${TEMP_DIR}/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz
tar -zxf ${TEMP_DIR}/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz -C ${TARGET_PATH} helmfile
# 安装 sops
curl -#fSLo ${TARGET_PATH}/sops https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${TARGETARCH}
# 安装 golang
curl -#fSLo ${TEMP_DIR}/go.tar.gz https://go.dev/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz
tar -zxf ${TEMP_DIR}/go.tar.gz -C /usr/local/
# argocd
curl -#fSLo ${TARGET_PATH}/argocd https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-${TARGETARCH}

# 授权，清理
chmod +x ${TARGET_PATH}/* 
rm -rf ${TEMP_DIR}