FROM centos:7
MAINTAINER P-O Quirion po.quirion@computequebec.ca

WORKDIR /tmp

# All yum cmd
RUN yum install -y  https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm \
  && yum install -y cvmfs.x86_64 wget unzip.x86_64 make.x86_64 gcc expectk dejagnu less tcl-devel.x86_64

# parrot
RUN wget http://ccl.cse.nd.edu/software/files/cctools-6.2.8-x86_64-redhat7.tar.gz \
  && tar xvf cctools-6.2.8-x86_64-redhat7.tar.gz && mv cctools-6.2.8-x86_64-redhat7 /opt/. && rm cctools-6.2.8-x86_64-redhat7.tar.gz
ADD cvmfs-config.computecanada.ca.pub /etc/cvmfs/keys/.
RUN chmod 4755 /bin/ping
RUN mkdir /etc/parrot 
# adding local config to containe. These will overwrite the cvmfs-config.computecanada ones
ADD config.d /etc/parrot/.
RUN mkdir /cvmfs-cache && chmod 777 /cvmfs-cache

# module
ENV MODULE_VERSION 4.1.2
RUN wget https://github.com/cea-hpc/modules/releases/download/v${MODULE_VERSION}/modules-${MODULE_VERSION}.tar.gz 
RUN tar xzf modules-${MODULE_VERSION}.tar.gz && \
    rm modules-${MODULE_VERSION}.tar.gz
RUN cd  modules-${MODULE_VERSION}  && ./configure && make -j 7  && make install
RUN ["ln", "-s", "/usr/local/Modules/init/profile.sh", "/etc/profile.d/z00_module.sh"]
RUN echo "source /etc/profile.d/z00_module.sh" >>  /etc/bashrc

ADD devmodule/genpipes "/usr/local/Modules/modulefiles/."

ADD genpiperc    /usr/local/etc/genpiperc
ADD init_all.sh /usr/local/bin/init_genpipes
RUN chmod 755 /usr/local/bin/init_genpipes


ENTRYPOINT ["init_genpipes", "-a", "/cvmfs-cache/cvmfs/shared/", "-c", "/etc/parrot/"]
# docker build --tag truite .
