# Create an Ubuntu Docker image for Raspberry Pi Pico development,
# with ARM toolchain and development environment prepared. The Pico
# SDK, extras, examples, and debugging tools are included, and are
# located at /opt/pico. The default nonprivileged user is "pico".
# The container is set up for a bind mount of a host directory to
# /mnt/host, with a symlink to this mount point from $HOME/host in
# the user's account.

# Generic Ubuntu container to start
FROM ubuntu:24.04
ENV USER=pico UID=1000 GID=1000
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update \
  && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get install -y python3 curl openssl sudo

# Add toolchains and utilities for Pico development
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get install -y git cmake gcc-arm-none-eabi libstdc++-arm-none-eabi-newlib \
    libstdc++-arm-none-eabi-dev gcc g++ ninja-build gdb-multiarch automake \
    autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev \
    libjim-dev pkg-config libgpiod-dev minicom\
  && rm -rf /var/lib/apt/lists/*

# Create default user
RUN userdel `id -u -n 1000` \
  && useradd -o -u ${UID} ${USER} \
  && usermod -aG sudo ${USER} \
  &&  echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USER} \
  && chmod 0440 /etc/sudoers.d/${USER}
RUN mkdir -p -m 777 /opt/pico && mkdir -p -m 777 /mnt/host
USER ${USER}
WORKDIR /home/${USER}
RUN touch .bashrc && ln -s /mnt/host host

# Install Pico SDK, extras, examples, FreeRTOS, and tools
ENV GITHUB_PREFIX=https://github.com/raspberrypi/ REPO_BRANCH=master GIT_SSL_NO_VERIFY=true
WORKDIR /opt/pico
RUN git clone -b ${REPO_BRANCH} ${GITHUB_PREFIX}pico-sdk.git && \
  cd pico-sdk && git submodule update --init --recursive && \
  echo "export PICO_SDK_PATH=/opt/pico/pico-sdk" >> /home/${USER}/.bashrc
RUN git clone -b ${REPO_BRANCH} ${GITHUB_PREFIX}pico-examples.git && \
  cd pico-examples && git submodule update --init --recursive && \
  echo "export PICO_EXAMPLES_PATH=/opt/pico/pico-examples" >> /home/${USER}/.bashrc
RUN git clone -b ${REPO_BRANCH} ${GITHUB_PREFIX}pico-extras.git && \
  cd pico-extras && git submodule update --init --recursive && \
  echo "export PICO_EXTRAS_PATH=/opt/pico/pico-extras" >> /home/${USER}/.bashrc
RUN git clone -b ${REPO_BRANCH} ${GITHUB_PREFIX}pico-playground.git && \
  cd pico-playground && git submodule update --init --recursive && \
  echo "export PICO_PLAYGROUND_PATH=/opt/pico/pico-playground" >> /home/${USER}/.bashrc
RUN git clone -b main ${GITHUB_PREFIX}FreeRTOS-Kernel.git && \
  cd FreeRTOS-Kernel && git submodule update --init --recursive && \
  echo "export FREERTOS_KERNEL_PATH=/opt/pico/FreeRTOS-Kernel" >> /home/${USER}/.bashrc

RUN git clone -b master ${GITHUB_PREFIX}picotool.git && \
  cd picotool && git submodule update --init --recursive
RUN git clone ${GITHUB_PREFIX}debugprobe.git && \
  cd debugprobe && git submodule update --init --recursive

# Build tools: picotool and debugprobe
RUN . /home/${USER}/.bashrc && cd picotool && cmake -S . -B build -GNinja && \
    cmake --build build
RUN . /home/${USER}/.bashrc && cd debugprobe && cmake -S . -B build -GNinja && \
    cmake --build build
USER root
WORKDIR /opt/pico/picotool
RUN . /home/${USER}/.bashrc && cmake --install build

# Change back to default user in home directory
USER ${USER}
WORKDIR /home/${USER}
