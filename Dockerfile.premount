FROM centos:7.6.1810
MAINTAINER P-O Quirion po.quirion@mcgill.ca

WORKDIR /tmp

# All yum cmd

ENV CCTOOLS_VERSION 7.0.16
ENV CVMFS_VERSION latest
ENV MODULE_VERSION 4.1.2
RUN yum update -y \
  && yum install -y wget unzip.x86_64 make.x86_64 gcc expectk dejagnu less tcl-devel.x86_64 \
  && yum clean all

RUN mkdir /cvmfs-cache  /cvmfs  && chmod 777 /cvmfs-cache  /cvmfs

# module
RUN wget https://github.com/cea-hpc/modules/releases/download/v${MODULE_VERSION}/modules-${MODULE_VERSION}.tar.gz
RUN tar xzf modules-${MODULE_VERSION}.tar.gz && \
    rm modules-${MODULE_VERSION}.tar.gz \
    && cd  modules-${MODULE_VERSION}  && ./configure && make -j 7  && make install \
    && cd .. && rm -rf modules-${MODULE_VERSION} && rm -rf /usr/local/Modules/modulefiles/*
RUN ["ln", "-s", "/usr/local/Modules/init/profile.sh", "/etc/profile.d/z00_module.sh"]
#RUN echo "source /etc/profile.d/z00_module.sh" >>  /etc/bashrc
ADD devmodule/genpipes "/usr/local/Modules/modulefiles/."

#RUN echo "source /etc/profile.d/z90_genpipes.sh" >>  /etc/bashrc
RUN ["ln", "-s", "/usr/local/etc/genpiperc", "/etc/profile.d/z90_genpipes.sh"]

ADD genpiperc    /usr/local/etc/genpiperc
ADD init_genpipes /usr/local/bin/init_genpipes
RUN chmod 755 /usr/local/bin/init_genpipes

ENTRYPOINT ["init_genpipes"]
# docker build --tag c3genomics/genpipes:beta .

