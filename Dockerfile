FROM ubuntu:24.04
LABEL authors="P-O Quirion po.quirion@mcgill.ca, Paul Stretenowich paul.stretenowich@mcgill.ca"

WORKDIR /tmp

ENV CVMFS_VERSION=latest
ENV CC_STACK=latest
ENV MODULE_VERSION=4.1.2

# All apt-get cmd
RUN apt-get update -y && \
    apt-get install -y wget lsb-release
RUN wget https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-${CVMFS_VERSION}_all.deb && \
    dpkg -i cvmfs-release-${CVMFS_VERSION}_all.deb && \
    rm -f cvmfs-release-${CVMFS_VERSION}_all.deb && \
    apt-get update -y && \
    apt-get install -y cvmfs
RUN wget https://package.computecanada.ca/yum/cc-cvmfs-public/prod/other/cvmfs-config-computecanada-${CC_STACK}.all.deb && \
    apt-get install -y ./cvmfs-config-computecanada-${CC_STACK}.all.deb && \
    rm -f cvmfs-config-computecanada-${CC_STACK}.all.deb
RUN apt-get install -y libpng-dev libjpeg-dev libtiff-dev && \
    apt-get install -y imagemagick pigz which zip unzip make gcc expect file dejagnu less tcl-dev cvmfs-config-computecanada cvmfs-fuse3 cvmfs-config-default && \
    apt-get clean all

RUN mkdir /cvmfs-cache  && chmod 777 /cvmfs-cache  /cvmfs
RUN mkdir /cvmfs/ref.mugqic /cvmfs/soft.mugqic /cvmfs/cvmfs-config.computecanada.ca

# module
RUN wget https://github.com/cea-hpc/modules/releases/download/v${MODULE_VERSION}/modules-${MODULE_VERSION}.tar.gz
RUN tar xzf modules-${MODULE_VERSION}.tar.gz && \
    rm modules-${MODULE_VERSION}.tar.gz \
    && cd  modules-${MODULE_VERSION}  && ./configure && make -j 7  && make install \
    && cd .. && rm -rf modules-${MODULE_VERSION} && rm -rf /usr/local/Modules/modulefiles/*

# CVMFS
ADD default.local /etc/cvmfs/default.local
ADD soft.mugqic.local /etc/cvmfs/config.d/soft.mugqic.local
ADD ref.mugqic.local /etc/cvmfs/config.d/ref.mugqic.local

RUN ["ln", "-s", "/usr/local/Modules/init/profile.sh", "/etc/profile.d/z00_module.sh"]
RUN echo "source /etc/profile.d/z00_module.sh" >>  /etc/bashrc

ADD genpipesrc /usr/local/etc/genpiperc
RUN ["ln", "-s", "/usr/local/etc/genpiperc", "/etc/profile.d/z90_genpipes.sh"]

ADD init_genpipes /usr/local/bin/init_genpipes
RUN chmod 755 /usr/local/bin/init_genpipes
ENTRYPOINT ["init_genpipes"]
