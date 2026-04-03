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
    systemd-sysv \
    procps \
    net-tools \
    iproute2 \
    gnupg2 \
    software-properties-common \
    lsb-release \
    apt-transport-https \
    ca-certificates \
    dbus

# Clean up systemd to make it Docker friendly
RUN cd /lib/systemd/system/sysinit.target.wants/; ls | grep -v systemd-tmpfiles-setup | xargs rm -f; \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    rm -f /lib/systemd/system/plymouth*; \
    rm -f /lib/systemd/system/systemd-update-utmp*;

VOLUME ["/sys/fs/cgroup"]

STOPSIGNAL SIGRTMIN+3

WORKDIR /root
CMD ["/lib/systemd/systemd"]
