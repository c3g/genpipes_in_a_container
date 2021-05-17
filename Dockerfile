FROM centos:7.9.2009
MAINTAINER P-O Quirion po.quirion@mcgill.ca

WORKDIR /tmp

# All yum cmd

ENV CVMFS_VERSION latest
ENV MODULE_VERSION 4.1.2
RUN yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm https://package.computecanada.ca/yum/cc-cvmfs-public/prod/RPM/computecanada-release-latest.noarch.rpm
RUN yum update -y \
  && yum install -y which wget unzip.x86_64 make.x86_64 gcc expectk \
  dejagnu less tcl-devel.x86_64 cvmfs-config-computecanada \
  cvmfs-fuse3 cvmfs-config-default \
  && yum clean all
# RUN yum install -y https://package.computecanada.ca/yum/cc-cvmfs-public/prod/RPM/computecanada-release-latest.noarch.rpm
# RUN yum update -y \
   # && yum install -y  cvmfs-config-computecanada

RUN mkdir /cvmfs-cache  && chmod 777 /cvmfs-cache  /cvmfs

# module
RUN wget https://github.com/cea-hpc/modules/releases/download/v${MODULE_VERSION}/modules-${MODULE_VERSION}.tar.gz
RUN tar xzf modules-${MODULE_VERSION}.tar.gz && \
    rm modules-${MODULE_VERSION}.tar.gz \
    && cd  modules-${MODULE_VERSION}  && ./configure && make -j 7  && make install \
    && cd .. && rm -rf modules-${MODULE_VERSION} && rm -rf /usr/local/Modules/modulefiles/*
# CVMFS
# RUN rm -r /etc/cvmfs/keys/* && mkdir -p  /cvmfs/ref.mugqic /cvmfs/soft.mugqic
# ADD docker/etc/keys/gen /etc/cvmfs/keys
ADD default.local /etc/cvmfs/default.local
ADD soft.mugqic.local /etc/cvmfs/config.d/soft.mugqic.local
ADD ref.mugqic.local /etc/cvmfs/config.d/ref.mugqic.local

RUN ["ln", "-s", "/usr/local/Modules/init/profile.sh", "/etc/profile.d/z00_module.sh"]
#RUN echo "source /etc/profile.d/z00_module.sh" >>  /etc/bashrc
# ADD devmodule/genpipes "/usr/local/Modules/modulefiles/."

#RUN echo "source /etc/profile.d/z90_genpipes.sh" >>  /etc/bashrc
# RUN ["ln", "-s", "/usr/local/etc/genpiperc", "/etc/profile.d/z90_genpipes.sh"]

# ADD docker/genpiperc    /usr/local/etc/genpiperc
# ADD init_genpipes /usr/local/bin/init_genpipes
# RUN chmod 755 /usr/local/bin/init_genpipes

# ENTRYPOINT ["init_genpipes"]
# docker build --tag c3genomics/genpipes:beta .
