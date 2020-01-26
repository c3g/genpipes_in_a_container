# Genpipes container

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

Fist, clone genpipes somewhere under your $HOME folder three. Then get the container wrapper:

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

# On SLURM HPC

Created an ini file that fits your system and for the pipeline(s) you want to use.


add the `--wrap` option when running the pipelines

# On PBS/torque flavored HPC

Created an ini file that fits your system and for the pipeline(s) you want to use.

add the `--wrap` option when running the pipelines


# On a single machine.


Just run the pipeline with the `--wrap` and `-j batch` and `--no-json` options!
