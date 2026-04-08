#!/bin/bash
set -euo pipefail

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

install_docker_amazon_linux() {
    yum update -y
    yum install -y docker
    systemctl enable docker
    systemctl start docker
}

install_docker_ubuntu() {
    apt-get update -y
    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker
}

OS=$(detect_os)

case "$OS" in
    amzn)
        echo "Detected Amazon Linux — installing Docker via yum..."
        install_docker_amazon_linux
        ;;
    ubuntu)
        echo "Detected Ubuntu — installing Docker via apt..."
        install_docker_ubuntu
        ;;
    *)
        echo "Unsupported OS: $OS" >&2
        exit 1
        ;;
esac

docker --version
echo "Docker installed successfully."
