FROM centos/s2i-base-centos7:latest
ENV SUMMARY="Red Hat CodeReady 1.2.2 Workspaces - HUGO Stack container" \
    DESCRIPTION="Red Hat CodeReady Workspaces 1.2.2- Python Stack container" \
    PRODNAME="codeready-workspaces" \
    COMPNAME="stacks-hugo-go" \
    HOME=/home/jboss\    
LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="$DESCRIPTION" \
      io.openshift.tags="$PRODNAME,$COMPNAME" \
      com.redhat.component="$PRODNAME-$COMPNAME-container" \
      name="$PRODNAME/$COMPNAME" \
      version="1.2" \
      license="EPLv2" \
      io.openshift.expose-services="" \
      usage="" \
      HUGO_VERSION="0.64.0"
USER root
# Add golang package
RUN yum install -y centos-release-scl-rh epel-release && \
    yum-config-manager --enable centos-sclo-rh-testing && \
    INSTALL_PKGS="golang" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS

RUN curl -fssL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz" | tar -xz -C /usr/local/bin

COPY ./s2i/* $STI_SCRIPTS_PATH/
RUN chmod -R 755 $STI_SCRIPTS_PATH/
RUN chown -R 0:0 /opt/app-root/
RUN chmod -R 774 /opt/app-root/

# Add CRW 1.2.2 packages
RUN useradd -u 1000 -G wheel,root -d ${HOME} --shell /bin/bash -m jboss && \
    yum remove -y kernel-headers && \
    yum install -y java-1.8.0-openjdk atomic-openshift-clients gcc && \
    yum update -y pango libnghttp2 && \
    yum clean all && rm -rf /var/cache/yum && \ 
    yum install -y net-tools && \
    pip install -U virtualenv && \
    pip install circus && \    
    mkdir -p ${HOME}/che /projects && \
    for f in "${HOME}" "/etc/passwd" "/etc/group" "/projects"; do \
        chgrp -R 0 ${f} && \
        chmod -R g+rwX ${f}; \
    done && \
    cat /etc/passwd | \
    sed s#jboss:x.*#jboss:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g \
    > ${HOME}/passwd.template && \
    cat /etc/group | \
    sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
    > ${HOME}/group.template && \
    echo "jboss	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers
# built in Brew, use get-sources-jenkins.sh to pull latest
COPY codeready-workspaces-stacks-language-servers-dependencies-python.tar.gz /tmp

# new line create dir /opt/app-root/bin /opt/app-root/lib 
RUN mkdir -p /opt/app-root/bin /opt/app-root/lib

RUN tar -xvf /tmp/codeready-workspaces-stacks-language-servers-dependencies-python.tar.gz -C /tmp && \
    cp -R /tmp/bin/* /opt/app-root/bin && cp -R /tmp/lib/* /opt/app-root/lib && \
    chgrp -R 0 /opt/app-root && chmod -R g+rwX /opt/app-root && \
    rm /tmp/codeready-workspaces-stacks-language-servers-dependencies-python.tar.gz && \
    echo "Installed Packages" && rpm -qa | sort -V && echo "End Of Installed Packages"

ADD entrypoint.sh ${HOME}/entrypoint.sh
USER jboss
# new line adding asset configuration
#ADD config.json /tmp/config.json
ADD requirements.txt /tmp/requirements.txt
RUN cd /tmp/ && pip install -r requirements.txt
ENTRYPOINT ["/home/jboss/entrypoint.sh"]
WORKDIR /projects
CMD tail -f /dev/null
# insert generated LABELs below this line
LABEL \
      git.commit.redhat-developer__codeready-workspaces-deprecated="https://github.com/redhat-developer/codeready-workspaces-deprecated/commit/dc2f" \
      pom.version.redhat-developer__codeready-workspaces-deprecated="1.2.0.GA-SNAPSHOT" \
      jenkins.build.url="https://codeready-workspaces-jenkins.rhev-ci-vms.eng.rdu2.redhat.com/view/CRW_CI/view/Pipelines/job/crw-operator-installer-and-ls-deps_stable-branch/80/" \
      jenkins.artifact.url="https://codeready-workspaces-jenkins.rhev-ci-vms.eng.rdu2.redhat.com/view/CRW_CI/view/Pipelines/job/crw-operator-installer-and-ls-deps_stable-branch/80/artifact/**/codeready-workspaces-stacks-language-servers-dependencies-python.tar.gz" \
      jenkins.build.number="80"
