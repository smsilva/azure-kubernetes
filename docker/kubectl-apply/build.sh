#!/bin/bash
export KUBECTL_VERSION="v${1-1.22.12}"

export DOCKERBUILD_CONTEXT_TEMPORARY_DIRECTORY="docker_build_temp"
export KUBECTL_DOWNLOADED_BINARY="${DOCKERBUILD_CONTEXT_TEMPORARY_DIRECTORY?}/kubectl_downloaded_binary"

mkdir -p "${DOCKERBUILD_CONTEXT_TEMPORARY_DIRECTORY?}"

if [ -z "${KUBECTL_DOWNLOADED_BINARY?}" ]; then
  curl \
    --silent \
    --location \
    --output "${KUBECTL_DOWNLOADED_BINARY?}" \
    --remote-name https://dl.k8s.io/release/v1.24.0/bin/linux/amd64/kubectl
fi

echo "kubectl:"
echo "  version: ${KUBECTL_VERSION}"

docker build \
  --tag kubectl:latest \
  .
