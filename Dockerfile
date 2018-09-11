FROM centos:7.5.1804
MAINTAINER P-O Quirion po.quirion@computequebec.ca

WORKDIR /tmp

# All yum cmd
RUN yum install -y  https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-2-6.noarch.rpm \
  && yum install -y cvmfs.x86_64 wget unzip.x86_64 make.x86_64 gcc expectk dejagnu less tcl-devel.x86_64


ADD cvmfs-config.computecanada.ca.pub /etc/cvmfs/keys/.
RUN chmod 4755 /bin/ping && echo user_allow_other > /etc/fuse.conf 
# adding local config to containe. These will overwrite the cvmfs-config.computecanada ones
ADD config.d /etc/cvmfs/config.d/.
RUN mkdir /cvmfs-cache && chmod 777 /cvmfs-cache \
&& mkdir /cvmfs/{ref.mugqic,soft.mugqic,cvmfs-config.computecanada.ca} && chmod 777 /cvmfs/{ref.mugqic,soft.mugqic,cvmfs-config.computecanada.ca}  \
&& mkdir  /var/run/cvmfs   && chmod 777  /run/cvmfs && chmod 777  /var/run/cvmfs && chmod 777 /var/lib/cvmfs

# module
ENV MODULE_VERSION 4.1.2
RUN wget https://github.com/cea-hpc/modules/releases/download/v${MODULE_VERSION}/modules-${MODULE_VERSION}.tar.gz 
RUN tar xzf modules-${MODULE_VERSION}.tar.gz && \
    rm modules-${MODULE_VERSION}.tar.gz
RUN cd  modules-${MODULE_VERSION}  && ./configure && make -j 7  && make install
RUN ["ln", "-s", "/usr/local/Modules/init/profile.sh", "/etc/profile.d/z00_module.sh"]
RUN echo "source /etc/profile.d/z00_module.sh" >>  /etc/bashrc
RUN rm -rf /usr/local/Modules/modulefiles/*
ADD devmodule/genpipes "/usr/local/Modules/modulefiles/."

ADD genpiperc    /usr/local/etc/genpiperc
ADD init_all.sh /usr/local/bin/init_genpipes
RUN chmod 755 /usr/local/bin/init_genpipes

#ENTRYPOINT ["init_genpipes", "-a", "/cvmfs-cache/cvmfs/shared/", "-c", "/etc/parrot/"]
ENTRYPOINT ["init_genpipes"]
# docker build --tag cccg/genpipes .
