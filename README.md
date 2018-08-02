# Genpipes container

A container to create and run Genpipes pipelines anywhere. Only user priviledge are required.

The [Genpipes](https://bitbucket.org/mugqic/genpipes/src/master/README.md) tools are design to run on Super Computers ([documentation here](http://www.computationalgenomics.ca/tutorials/)), however, you can generate generate the pipelines scripts and run smaller experiment on a server with container technology. Containers can also be used to debug and develop [Genpipes](https://bitbucket.org/mugqic/genpipes/src/master/README.md) on you machine.

## Install a compatible container technology on your machine (Linux, Mac, or Windows)

 - [Docker](https://docs.docker.com/install/)
 - [Singularity](https://singularity.lbl.gov/index.html)

Then run with docker 
```
#!bash
docker run --privileged -v /tmp:/tmp --network host -it -w $PWD -v $HOME:$HOME --user $UID:$GROUPS -v /etc/group:/etc/group  -v /etc/passwd:/etc/passwd  [ -v < CACHE_ON_HOST >:/cvmfs-cache/ ] cccg/genpipes:<TAG>
```

or singularity
```
#!bash
singularity run [ -B < /HOST/CACHE/ >:/cvmfs-cache/  ] docker://cccg/genpipes:<TAG>
```


You can also [Read the genpipes documentation](https://bitbucket.org/mugqic/genpipes)

Here is [the project's Docker hub page](https://hub.docker.com/r/cccg/genpipes/)


## Setup a dev enviroment

You can use this container to develop and test new version of GenPipes.

Fist, clone genpipe somewhere under your $HOME folder three. 

```
git clone https://bitbucket.org/mugqic/genpipes $HOME/some/dir/genpipes
```
Add the followin line to your .bashrc

```
export GENPIPES_DEV_DIR=$HOME/some/dir/genpipes
```

Start the container with the normal procedure seen above. In the running container, execute the followin command:

```
 module load dev_genpipes
```

Voilà, now GenPipes uses whatever commmit of branch that has been checked out in $HOME/some/dir/genpipes


