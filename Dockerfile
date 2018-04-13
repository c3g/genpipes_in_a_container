FROM centos:7
MAINTAINER P-O Quirion po.quirion@computequebec.ca

WORKDIR /tmp
RUN yum install -y  https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm \
  && yum install -y cvmfs.x86_64 
RUN yum install -y wget 
RUN wget http://ccl.cse.nd.edu/software/files/cctools-6.2.8-x86_64-redhat7.tar.gz \
  && tar xvf cctools-6.2.8-x86_64-redhat7.tar.gz && mv cctools-6.2.8-x86_64-redhat7 /opt/. && rm cctools-6.2.8-x86_64-redhat7.tar.gz
ADD cvmfs-config.computecanada.ca.pub /etc/cvmfs/keys/.
RUN chmod 4755 /bin/ping
#ADD parrot.sh /usr/local/bin/init_parrot
#RUN chmod 755 /usr/local/bin/init_parrot
#ENTRYPOINT ["./parrot.sh"]
# docker build --tag truite .
