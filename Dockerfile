FROM mhart/alpine-node:16
LABEL maintainer="devops@signiant.com"

# Add our bldmgr user
ENV BUILD_USER bldmgr
ENV BUILD_PASS bldmgr
ENV BUILD_USER_ID 10012
ENV BUILD_USER_GROUP users

COPY apk.packages.list /tmp/apk.packages.list
RUN chmod +r /tmp/apk.packages.list && \
    apk --update add `cat /tmp/apk.packages.list` && \
    rm -rf /var/cache/apk/*

# Upgrade pip
RUN python3 -m ensurepip && python3 -m pip install --upgrade pip

# Install PIP packages
COPY pip.packages.list /tmp/pip.packages.list
RUN python3 -m pip install -r /tmp/pip.packages.list
RUN az bicep install

#install packer
RUN wget https://releases.hashicorp.com/packer/1.9.4/packer_1.9.4_linux_amd64.zip

RUN mkdir /usr/local/packer && \
    mkdir /root/goworkspace && \
    unzip packer_1.9.4_linux_amd64.zip -d /usr/local/packer

RUN /usr/local/packer/packer plugins install github.com/hashicorp/azure && \
    /usr/local/packer/packer plugins install github.com/hashicorp/googlecompute

ENV GOROOT=/usr/lib/go
ENV GOBIN=/usr/local/packer
ENV GOPATH=/root/goworkspace