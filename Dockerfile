FROM mhart/alpine-node:4
MAINTAINER devops@signiant.com

# Add our bldmgr user
ENV BUILD_USER bldmgr
ENV BUILD_PASS bldmgr
ENV BUILD_USER_ID 10012
ENV BUILD_USER_GROUP users

COPY apk.packages.list /tmp/apk.packages.list
RUN chmod +r /tmp/apk.packages.list && \
    apk --update add `cat /tmp/apk.packages.list` && \
    rm -rf /var/cache/apk/*

# Install pip
RUN cd /tmp && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python ./get-pip.py

# Install PIP packages
RUN pip3 install umpire --pre
RUN pip3 install --upgrade pip
RUN pip3 install azure-cli
COPY pip.packages.list /tmp/pip.packages.list
RUN chmod +r /tmp/pip.packages.list && \
    pip3 install `cat /tmp/pip.packages.list | tr \"\\n\" \" \"`

#install packer
RUN wget https://releases.hashicorp.com/packer/1.5.1/packer_1.5.1_linux_amd64.zip

RUN mkdir /usr/local/bin/packer && \
    mkdir /home/bldmgr/goworkspace && \
    unzip packer_1.5.1_linux_amd64.zip -d /usr/local/bin/packer

ENV GOROOT=/usr/lib/go
ENV GOBIN=/usr/local/bin/packer
ENV GOPATH=/home/bldmgr/goworkspace