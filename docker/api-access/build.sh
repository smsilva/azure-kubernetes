#!/bin/bash
export KUBECTL_VERSION="${1-1.22.12}"
export DOCKERBUILD_CONTEXT_TEMPORARY_DIRECTORY="docker_build_temp"
export KUBECTL_DOWNLOADED_BINARY="${DOCKERBUILD_CONTEXT_TEMPORARY_DIRECTORY?}/kubectl_downloaded_binary"

mkdir -p "${DOCKERBUILD_CONTEXT_TEMPORARY_DIRECTORY?}"

if ! [ -e "${KUBECTL_DOWNLOADED_BINARY?}" ]; then
  wget \
    --output-document ${KUBECTL_DOWNLOADED_BINARY?} \
    https://dl.k8s.io/release/v${KUBECTL_VERSION?}/bin/linux/amd64/kubectl
fi

echo "kubectl:"
echo "  version: ${KUBECTL_VERSION}"

docker build \
  --tag kubectl:latest \
  .
