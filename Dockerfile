FROM centos:7
MAINTAINER P-O Quirion po.quirion@computequebec.ca

WORKDIR /tmp

# All yum cmd
RUN yum install -y  https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm \
  && yum install -y cvmfs.x86_64 wget lua-devel.x86_64 unzip.x86_64 make.x86_64 gcc expectk 

# parrot
RUN wget http://ccl.cse.nd.edu/software/files/cctools-6.2.8-x86_64-redhat7.tar.gz \
  && tar xvf cctools-6.2.8-x86_64-redhat7.tar.gz && mv cctools-6.2.8-x86_64-redhat7 /opt/. && rm cctools-6.2.8-x86_64-redhat7.tar.gz
ADD cvmfs-config.computecanada.ca.pub /etc/cvmfs/keys/.
RUN chmod 4755 /bin/ping
RUN mkdir /etc/parrot 
ADD config.d /etc/parrot/. 
RUN mkdir /cvmfs-cache && chmod 777 /cvmfs-cache

# lmod (module)
ENV LUAROCKS_VERSION 2.4.2
ENV LUAROCKS_INSTALL luarocks-$LUAROCKS_VERSION
ENV LMOD_V 7.7.22
RUN wget  https://luarocks.org/releases/${LUAROCKS_INSTALL}.tar.gz
RUN tar xzf $LUAROCKS_INSTALL.tar.gz && \
    rm $LUAROCKS_INSTALL.tar.gz
RUN cd luarocks-$LUAROCKS_VERSION && ./configure && make build && make install

RUN luarocks install luaposix; luarocks install luafilesystem
ENV LUAROCKS_PREFIX /usr/local
ENV LUA_PATH "$LUAROCKS_PREFIX/share/lua/5.1/?.lua;$LUAROCKS_PREFIX/share/lua/5.1/?/init.lua;;"
ENV LUA_CPATH "$LUAROCKS_PREFIX/lib/lua/5.1/?.so;;"
RUN wget https://github.com/TACC/Lmod/archive/$LMOD_V.tar.gz && tar -xvf $LMOD_V.tar.gz 
RUN cd Lmod-$LMOD_V && ./configure --prefix=/opt/apps && make install
RUN ["ln", "-s", "/opt/apps/lmod/lmod/init/profile", "/etc/profile.d/z00_lmod.sh"]
RUN echo "source /etc/profile.d/z00_lmod.sh" >>  /etc/bashrc

ADD genpiperc    /usr/local/etc/genpiperc
ADD init_all.sh /usr/local/bin/init_all
ADD init_all.sh /usr/local/bin/init_all
RUN chmod 755 /usr/local/bin/init_all

ENTRYPOINT ["init_all", "-a", "/cvmfs-cache/cvmfs/shared/", "-c", "/etc/parrot/"]
# docker build --tag truite .
