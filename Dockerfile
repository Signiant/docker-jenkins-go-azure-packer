FROM signiant/docker-jenkins-centos-base:centos7
MAINTAINER devops@signiant.com

# Set the timezone
RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

# Install wget which we need later
RUN yum install -y wget

# Install device mapper libraries for docker
RUN yum install -y deltarpm device-mapper device-mapper-event device-mapper-libs device-mapper-event-libs

# Install EPEL
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

# Install the repoforge repo (needed for updated git)
RUN wget http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm -O /tmp/repoforge.rpm
RUN yum install -y /tmp/repoforge.rpm
RUN rm -f /tmp/repoforge.rpm

COPY yum-packages.list /tmp/yum.packages.list
RUN chmod +r /tmp/yum.packages.list
RUN yum install -y `cat /tmp/yum.packages.list`

# Install PIP
RUN /usr/bin/curl -O https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py

# Install PIP packages
COPY pip.packages.list /tmp/pip.packages.list
RUN chmod +r /tmp/pip.packages.list
RUN /bin/bash -l -c "pip install `cat /tmp/pip.packages.list | tr \"\\n\" \" \"`"

# make sure we're running latest of everything
RUN yum update -y

# install azure-cli
RUN npm install azure-cli -g

RUN wget https://releases.hashicorp.com/packer/0.9.0/packer_0.9.0_linux_amd64.zip

RUN mkdir /usr/local/bin/packer
RUN mkdir /var/lib/jenkins/workspace

RUN unzip packer_0.9.0_linux_amd64.zip -d /usr/local/bin/packer

ENV GOROOT=/usr/lib/golang
ENV GOBIN=/usr/local/bin/packer
ENV GOPATH=/var/lib/jenkins/workspace

RUN go get github.com/Azure/packer-azure/packer/plugin/packer-builder-azure
RUN go get github.com/Azure/packer-azure/packer/plugin/packer-provisioner-azure-custom-script-extension

# Make sure anything/everything we put in the build user's home dir is owned correctly
RUN chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER

EXPOSE 22

# This entry will either run this container as a jenkins slave or just start SSHD
# If we're using the slave-on-demand, we start with SSH (the default)

# Default Jenkins Slave Name
ENV SLAVE_ID JAVA_NODE
ENV SLAVE_OS Linux

ADD start.sh /
RUN chmod 777 /start.sh
