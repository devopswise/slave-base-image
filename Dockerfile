# Copyright (c) 2012-2016 Codenvy, S.A.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# Contributors:
# Codenvy, S.A. - initial API and implementation

FROM debian:jessie
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH
RUN echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y install \
    openssh-server \
    sudo \
    rsync \
    procps \
    -t jessie-backports \
    openjdk-8-jdk-headless=8u171-b11-1~bpo8+1 \
    openjdk-8-source=8u171-b11-1~bpo8+1 \
    wget \
    unzip \
    mc \
    locales \
    ca-certificates \
    curl \
    bash-completion && \
    mkdir /var/run/sshd && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -u 1000 -G users,sudo -d /home/user --shell /bin/bash -m user && \
    usermod -p "*" user && \
    sudo echo -e "deb http://ppa.launchpad.net/git-core/ppa/ubuntu precise main\ndeb-src http://ppa.launchpad.net/git-core/ppa/ubuntu precise main" >> /etc/apt/sources.list.d/sources.list && \
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A1715D88E1DF1F24 && \
    sudo apt-get install git subversion -y && \
    apt-get clean && \
    apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

#    wget vim python-pip s3cmd \

ENV DOCKER_VERSION=18.03.1-ce \
    DOCKER_BUCKET=download.docker.com
RUN wget -qO- https://${DOCKER_BUCKET}/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar xvz docker/docker --strip-components=1 && mv ./docker /usr/bin/docker
#RUN curl -sSL "https://${DOCKER_BUCKET}/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" -o /usr/bin/docker && \
#    chmod +x /usr/bin/docker

#RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
#    libssl-dev apt-transport-https ca-certificates curl gnupg2 \
#    && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
#    && echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" > /etc/apt/sources.list.d/docker-ce.list \
#    && apt-get update && apt-get install -y docker-ce \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG C.UTF-8
USER user
RUN sudo localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    svn --version && \
    sed -i 's/# store-passwords = no/store-passwords = yes/g' /home/user/.subversion/servers && \
    sed -i 's/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g' /home/user/.subversion/servers
COPY open-jdk-source-file-location /open-jdk-source-file-location
EXPOSE 22 4403
WORKDIR /projects


# The following instructions set the right
# permissions and scripts to allow the container
# to be run by an arbitrary user (i.e. a user
# that doesn't already exist in /etc/passwd)
ENV HOME /home/user
RUN for f in "/home/user" "/etc/passwd" "/etc/group" "/projects"; do\
           sudo chgrp -R 0 ${f} && \
           sudo chmod -R g+rwX ${f}; \
        done && \
        # Generate passwd.template \
        cat /etc/passwd | \
        sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g \
        > /home/user/passwd.template && \
        # Generate group.template \
        cat /etc/group | \
        sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
        > /home/user/group.template && \
        sudo sed -ri 's/StrictModes yes/StrictModes no/g' /etc/ssh/sshd_config

COPY ["entrypoint.sh","/home/user/entrypoint.sh"]

ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD tail -f /dev/null



#FROM jenkinsci/ssh-slave

ENV GIT_SSL_NO_VERIFY TRUE

#RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
#    make curl wget vim python-pip s3cmd \
#    libssl-dev apt-transport-https ca-certificates curl gnupg2 \
#    && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
#    && echo "deb [arch=amd64] https://download.docker.com/linux/debian stretch stable" > /etc/apt/sources.list.d/docker-ce.list \
#    && apt-get update && apt-get -y dist-upgrade && apt-get install -y maven docker-ce \
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN usermod -a -G root jenkins
#RUN echo 'jenkins ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
