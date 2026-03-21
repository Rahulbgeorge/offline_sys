FROM ubuntu:24.04

# Prevent interactive prompts during apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic tools including required networking and system utilities
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    curl \
    wget \
    git \
    nano \
    vim \
    sudo \
    openssl \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    systemd \
    procps \
    net-tools \
    iproute2 \
    gnupg2 \
    software-properties-common \
    lsb-release \
    apt-transport-https \
    ca-certificates

WORKDIR /root
