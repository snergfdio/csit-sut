# Copyright (c) 2019 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:18.04
MAINTAINER csit-dev <csit-dev@lists.fd.io>
LABEL Description="CSIT vpp-device ubuntu 18.04 SUT image"
LABEL Version="0.7"

# Setup the environment
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV NOTVISIBLE "in users profile"
ENV VPP_PYTHON_PREFIX=/var/cache/vpp/python

# Install packages and Docker
RUN apt-get -q update \
 && apt-get install -y -qq \
        # general tools
        apt-transport-https \
        bridge-utils \
        cloud-init \
        curl \
        locales \
        net-tools \
        openssh-server \
        pciutils \
        rsyslog \
        software-properties-common \
        ssh \
        sudo \
        supervisor \
        tar \
        vim \
        wget \
        # csit requirements
        cmake \
        dkms \
        gfortran \
        libblas-dev \
        liblapack-dev \
        libpcap-dev \
        openjdk-8-jdk-headless \
        python-all \
        python-apt \
        python-cffi \
        python-cffi-backend \
        python-dev \
        python-enum34 \
        python-pip \
        python-setuptools \
        python-virtualenv \
        python3-all \
        python3-apt \
        python3-cffi \
        python3-cffi-backend \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-virtualenv \
        qemu-system \
        socat \
        strongswan \
        unzip \
        tcpdump \
        zlib1g-dev \
        # vpp requirements
        ca-certificates \
        libapr1 \
        libmbedcrypto1 \
        libmbedtls10 \
        libmbedx509-0 \
        libnuma1 \
        sshpass \
 && curl -L https://packagecloud.io/fdio/master/gpgkey | sudo apt-key add - \
 && curl -s https://packagecloud.io/install/repositories/fdio/master/script.deb.sh | sudo bash \
 # temp hack due to build.sh
 && apt-get install -y -qq vpp-ext-deps \
 && curl -fsSL https://get.docker.com | sh \
 && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN locale-gen en_US.UTF-8 \
 && dpkg-reconfigure locales

# Fix permissions
RUN chown root:syslog /var/log \
 && chmod 755 /etc/default

# Create directory structure
RUN mkdir -p /tmp/dumps \
 && mkdir -p /var/cache/vpp/python \
 && mkdir -p /var/run/sshd

# CSIT PIP pre-cache
RUN pip install \
        aenum==2.1.2 \
        docopt==0.6.2 \
        ecdsa==0.13 \
        enum34==1.1.2 \
        ipaddress==1.0.16 \
        paramiko==1.16.0 \
        pexpect==4.6.0 \
        pycrypto==2.6.1 \
        pykwalify==1.5.0 \
        pypcap==1.1.5 \
        python-dateutil==2.4.2 \
        PyYAML==3.11 \
        requests==2.9.1 \
        robotframework==2.9.2 \
        scapy==2.3.1 \
        scp==0.10.2 \
        six==1.12.0 \
        dill==0.2.8.2 \
        numpy==1.14.5

# ARM workaround
RUN pip install scipy==1.1.0

# SSH settings
RUN echo 'root:Csit1234' | chpasswd \
 && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
 && echo "export VISIBLE=now" >> /etc/profile

EXPOSE 2222

COPY supervisord.conf /etc/supervisor/supervisord.conf

CMD ["sh", "-c", "rm -f /dev/shm/db /dev/shm/global_vm /dev/shm/vpe-api; /usr/bin/supervisord -c /etc/supervisord/supervisord.conf; /usr/sbin/sshd -D -p 2222"]
