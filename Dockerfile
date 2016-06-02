FROM mhart/alpine-node:4
MAINTAINER devops@signiant.com

ENV BUILD_USER bldmgr
ENV BUILD_USER_GROUP users

RUN apk --update add openjdk7-jre openssh git python wget nginx go && \
    rm -rf /var/cache/apk/*

RUN npm install -g npm@${NPM_VERSION} && \
  find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf && \
  rm -rf /usr/share/man /tmp/* /root/.npm /root/.node-gyp \
    /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html

# Install pip
RUN cd /tmp && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python ./get-pip.py

# Install PIP packages
COPY pip.packages.list /tmp/pip.packages.list
RUN chmod +r /tmp/pip.packages.list && \
    pip install `cat /tmp/pip.packages.list | tr \"\\n\" \" \"`

# install azure-cli
RUN npm install azure-cli -g

RUN addgroup jenkins && \
    adduser -D $BUILD_USER -s /bin/sh -G $BUILD_USER_GROUP && \
    chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER && \
    echo "$BUILD_USER:$BUILD_USER" | chpasswd

RUN wget https://releases.hashicorp.com/packer/0.9.0/packer_0.9.0_linux_amd64.zip

RUN mkdir /usr/local/bin/packer
RUN mkdir /home/bldmgr/goworkspace

RUN unzip packer_0.9.0_linux_amd64.zip -d /usr/local/bin/packer

ENV GOROOT=/usr/lib/go
ENV GOBIN=/usr/local/bin/packer
ENV GOPATH=/home/bldmgr/goworkspace
RUN export PATH=$PATH:/usr/lib/go/bin

RUN go get github.com/Azure/packer-azure/packer/plugin/packer-provisioner-azure-custom-script-extension



EXPOSE 22

# This entry will either run this container as a jenkins slave or just start SSHD
# If we're using the slave-on-demand, we start with SSH (the default)

# Default Jenkins Slave Name
ENV SLAVE_ID JAVA_NODE
ENV SLAVE_OS Linux

ADD start.sh /
RUN chmod 777 /start.sh

CMD ["sh", "/start.sh"]
