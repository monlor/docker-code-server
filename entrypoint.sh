#!/bin/sh
set -eu

export EXTRA_PARAMS=""

# We do this first to ensure sudo works below when renaming the user.
# Otherwise the current container UID may not exist in the passwd database.
eval "$(fixuid -q)"

if [ "${DOCKER_USER-}" ]; then
  USER="$DOCKER_USER"
  if [ "$DOCKER_USER" != "$(whoami)" ]; then
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd > /dev/null
    # Unfortunately we cannot change $HOME as we cannot move any bind mounts
    # nor can we bind mount $HOME into a new home as that requires a privileged container.
    sudo usermod --login "$DOCKER_USER" coder
    sudo groupmod -n "$DOCKER_USER" coder

    sudo sed -i "/coder/d" /etc/sudoers.d/nopasswd
  fi
fi

# Allow users to have scripts run on container startup to prepare workspace.
# https://github.com/coder/code-server/issues/5177
if [ -d "${ENTRYPOINTD}" ]; then
  find "${ENTRYPOINTD}" -type f -executable -print -exec {} \;
fi

# proxy domain
if [ -n "${PROXY_DOMAIN}" ]; then
  EXTRA_PARAMS="--proxy-domain ${PROXY_DOMAIN} ${EXTRA_PARAMS}"
fi

# custom scripts
/opt/start.sh

exec dumb-init /usr/bin/code-server "$@" "${EXTRA_PARAMS}"