# Genpipes container Singularity.

You can use Genpipes in a Container (GiaC) to run Genpipes on a single machine, on a a Torque/PBS cluster or on a SLURM cluster.

If FUSE and [Singularity](https://singularity.lbl.gov/index.html) is installed on your machine you are all set, a simple user with no special privilege is enough.

While you can use (GiaC) to debug and develop Genpipes on you machine on you machine, [Genpipes](https://bitbucket.org/mugqic/genpipes/src/master/README.md) is design to run analysis on Super Computers.  


## Install a compatible container technology on your machine
Follow installation procedure from te  [Singularity install page](https://sylabs.io/guides/3.5/admin-guide/installation.html)


You can also [Read the genpipes documentation](https://bitbucket.org/mugqic/genpipes)

## What exactly is avalable in that container?

The full tested and integrated C3G/MUGQIC software stack.
[For more details: http://www.computationalgenomics.ca/cvmfs-modules/](http://www.computationalgenomics.ca/cvmfs-modules/)


## Setup a GiaC environment

You can use this container to develop and test new version of GenPipes.

Fist, clone Genpipes somewhere under your $HOME folder three. Then get the container wrapper:

```
git clone https://bitbucket.org/mugqic/genpipes $WORKDIR/genpipes

$WORKDIR/genpipes/resources/container/get_wrapper.sh

```

You can now configuere the `$WORKDIR/genpipes/resources/container/etc/wrapper.conf` file:

```
# GEN_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GEN_SHARED_CVMFS=$HOME/cvmfs
TMPDIR=/tmp
export UMOUNT_RETRY=5
BIND_LIST=
```

`GEN_SHARED_CVMFS` will hold a cache for GiaC [CVMFS](https://cernvm.cern.ch/portal/filesystem) system, it will hold the genomes and software being used by Genpipes. This folder will grow with Genpipes usage. You can delete in in between usage, but keep in mind that once deleted it will need to be rebuild by downloading data form the internet.

`BIND_LIST` is a list of file system, separated by comma, you need Genpipes to have access to, by default, only your $HOME is mounted. For example if you are on an HPC system with a `/scratch` and `/data` space, you would have `BIND_LIST=/scratch,/data`. The string will be fed to Singularity `--bind` option, see `singularity --help` for more details.

`TMPDIR` place to store GiaC temp files. These are a mainly metadata of what will be stored in the `GEN_SHARED_CVMFS` folder. The volume of data in this folder will be small.

`UMOUNT_RETRY` GiaC will mount a [CVMFS](https://cernvm.cern.ch/portal/filesystem) in the `TMPDIR` folder, once GiaC is done, the folder is unmounted up to `UMOUNT_RETRY` time, usually two try does the trick, but 5 is safer.  


You do not need any other setup on your machine.

## PIPELINE USAGE

### On SLURM HPC

Created an ini file that fits your system and for the pipeline(s) you want to use.


add the `--wrap` option when running the pipelines creation command.

### On PBS/torque flavored HPC

Created an ini file that fits your system and for the pipeline(s) you want to use.

add the `--wrap` option when running the pipelines  creation command.


### On a single machine.

Just run the pipeline with the `--wrap` and `-j batch` and `--no-json` options!

# Genpipes container Docker

The full setup is more simple with docker, but you need to be allowed to be
an administrator to install and run it.

Right now the docker version has only been tested on a single machine mode.


## Use Genpipes inside a Docker container
Docker and fuse need to be installed on you system.

```
# pull the latest docker image
docker pull c3genomics/genpipes:latest
# run Docker with the right options
# create a folder where the caching will happen It need to be accessible by the
# cvmfs user inside the container
mkdir  $HOME/cvmfs_cache &&  chmod 777  $HOME/cvmfs_cache
# run the container
docker run --rm  --security-opt apparmor:unconfined   --device /dev/fuse --cap-add SYS_ADMIN  -v /tmp:/tmp -it -w $PWD -v $HOME:$HOME -v /etc/group:/etc/group  -v /etc/passwd:/etc/passwd  -v $HOME/cvmfs_cache/:/cvmfs-cache/ c3genomics/genpipes
```
```
# here are the logs you will see
CernVM-FS: running with credentials 999:997 # this is the user that needs access to the cache
CernVM-FS: loading Fuse module... done
CernVM-FS: mounted cvmfs on /cvmfs/ref.mugqic
CernVM-FS: running with credentials 999:997
CernVM-FS: loading Fuse module... done
CernVM-FS: mounted cvmfs on /cvmfs/soft.mugqic
# you are in the container now.
```
Then check that all is in place
```
module avail
dnaseq.py -h
```
The first time a command is ran it will take time to complete since the cache
needs to be built. The second time, it should be instantaneous.

### Trouble shooting
To be able to run the docker container with the host uid, fuse need to be
accessible to non root user.
This is good
```
$ ls -l  /dev/fuse
crw-rw-rw- 1 root root 10, 229 Jun 19 11:49 /dev/fuse
```
This would be bad
```
$ ls -l  /dev/fuse
crw-rw---- 1 root root 10, 229 Jun 19 11:49 /dev/fuse
```
To solve that problem, you can open access to the fuse device:

```
chmod 666 /dev/fuse
```
or run the container as root (well the other option is better!)
