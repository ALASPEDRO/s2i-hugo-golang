FROM registry.redhat.io/codeready-workspaces/stacks-golang-rhel8:latest
ENV SUMMARY="Red Hat CodeReady 1.2.2 Workspaces - golang hugo Stack container" \
    DESCRIPTION="Red Hat CodeReady Workspaces 1.2.2- golang hugo Stack container" \
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

USER jboss
WORKDIR /projects
CMD tail -f /dev/null
