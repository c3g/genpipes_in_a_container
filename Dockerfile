FROM almalinux:9
LABEL authors="P-O Quirion po.quirion@mcgill.ca, Paul Stretenowich paul.stretenowich@mcgill.ca"

WORKDIR /tmp

# See https://ecsft.cern.ch/dist/cvmfs/cvmfs-release to decide version, if something else than "latest" make sure to edit the name "cvmfs-release-${CVMFS_VERSION}.noarch.rpm" accordingly
ENV CVMFS_VERSION=latest
# See https://package.computecanada.ca/yum/cc-cvmfs-public/prod/RPM to decide version
ENV CC_STACK=2.1.0-1
# See https://github.com/envmodules/modules/releases to decide version
ENV MODULE_VERSION=5.5.0

# All yum commands
RUN yum update -y && \
    yum install -y wget epel-release && \
    yum config-manager --set-enabled crb && \
    wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-${CVMFS_VERSION}.noarch.rpm && \
    rpm -i cvmfs-release-${CVMFS_VERSION}.noarch.rpm && \
    rm -f cvmfs-release-${CVMFS_VERSION}.noarch.rpm && \
    yum update -y && \
    yum install -y cvmfs && \
    wget https://package.computecanada.ca/yum/cc-cvmfs-public/prod/RPM/cvmfs-config-computecanada-${CC_STACK}.noarch.rpm && \
    yum install -y ./cvmfs-config-computecanada-${CC_STACK}.noarch.rpm && \
    rm -f cvmfs-config-computecanada-${CC_STACK}.noarch.rpm && \
    yum install -y libpng-devel libjpeg-devel libtiff-devel && \
    yum install -y ImageMagick pigz which zip unzip make gcc expect file dejagnu less tcl-devel cvmfs-config-computecanada cvmfs-fuse3 cvmfs-config-default && \
    yum clean all

RUN mkdir /cvmfs-cache && chmod 777 /cvmfs-cache /cvmfs
RUN mkdir /cvmfs/ref.mugqic /cvmfs/soft.mugqic /cvmfs/cvmfs-config.computecanada.ca

# module
RUN wget https://github.com/cea-hpc/modules/releases/download/v${MODULE_VERSION}/modules-${MODULE_VERSION}.tar.gz && \
    tar xzf modules-${MODULE_VERSION}.tar.gz && \
    rm modules-${MODULE_VERSION}.tar.gz && \
    cd modules-${MODULE_VERSION} && ./configure && make -j 7 && make install && \
    cd .. && rm -rf modules-${MODULE_VERSION} && rm -rf /usr/local/Modules/modulefiles/*

# CVMFS
ADD default.local /etc/cvmfs/default.local
ADD soft.mugqic.local /etc/cvmfs/config.d/soft.mugqic.local
ADD ref.mugqic.local /etc/cvmfs/config.d/ref.mugqic.local

RUN ["ln", "-s", "/usr/local/Modules/init/profile.sh", "/etc/profile.d/z00_module.sh"]
RUN echo "source /etc/profile.d/z00_module.sh" >> /etc/bashrc

ADD genpipesrc /usr/local/etc/genpiperc
RUN ["ln", "-s", "/usr/local/etc/genpiperc", "/etc/profile.d/z90_genpipes.sh"]

ADD init_genpipes /usr/local/bin/init_genpipes
RUN chmod 755 /usr/local/bin/init_genpipes
ENTRYPOINT ["init_genpipes"]
