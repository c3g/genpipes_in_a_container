# GenPipes in a container

You can use GenPipes in a Container (GiaC) to run GenPipes on a single machine, on a a Torque/PBS cluster or on a SLURM cluster.

If [Singularity](https://github.com/hpcng/singularity) is installed on your LINUX machine you are all set, a simple user with no special privilege is enough (no sudo needed).

While you can use (GiaC) to debug and develop GenPipes on your laptop, [GenPipes](https://bitbucket.org/mugqic/genpipes/src/master/README.md) is design to run analysis on Super Computers.  


## Install a compatible container technology on your machine
Follow installation procedure from the  [Singularity install page](ttps://github.com/hpcng/singularity/blob/master/INSTALL.md)


You can also [Read the GenPipes documentation](https://genpipes.readthedocs.io/)

## What exactly is avalable in that container?

The full tested and integrated C3G/MUGQIC software stack, a complete set of genomics references.
[For more details: http://www.computationalgenomics.ca/cvmfs-modules/](http://www.computationalgenomics.ca/cvmfs-modules/)


## Setup a GiaC environment

You can use this container to develop and test new version of GenPipes.

Fist, clone GenPipes somewhere under your $HOME folder three. Then get the container wrapper:

```
git clone https://bitbucket.org/mugqic/genpipes $WORKDIR/genpipes

$WORKDIR/genpipes/resources/container/get_wrapper.sh

```

You can now configuere the `$WORKDIR/genpipes/resources/container/etc/wrapper.conf` file:

```
# GEN_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GEN_SHARED_CVMFS=$HOME/cvmfs
BIND_LIST=
```

`GEN_SHARED_CVMFS` will hold a cache for GiaC [CVMFS](https://cernvm.cern.ch/portal/filesystem) system, it will hold the genomes and software being used by GenPipes. This folder will grow with GenPipes usage. You can delete it in between usage, but keep in mind that once deleted it will need to be rebuild by downloading data form the internet.

`BIND_LIST` is a list of file system, separated by comma, you need GenPipes to have access to, by default, only your $HOME is mounted. For example if you are on an HPC system with a `/scratch` and `/data` space, you would have `BIND_LIST=/scratch,/data`. The string will be fed to Singularity `--bind` option, see `singularity --help` for more details.

You do not need any other setup on your machine.

## PIPELINE USAGE

The GenPipes documentation page is here:
https://genpipes.readthedocs.io/

# On SLURM or PBS/torque HPC

Create an ini file that fits your system and for the pipeline(s) you want to use.

Add the `-j {pbs,slurm}` option to fit your scheduler then the `--wrap` options so GenPipes with wrap all its command with the container instrumentation.

# On a single machine.
## With the wrapper 
Run the pipeline with the `--wrap`, `-j batch` and `--no-json` options!

You can also run the `./genpipes/resources/container/bin/container_wrapper.sh` command to get inside the container with the right configuration. You will then have access to all the GenPipes tools be able to run them directly inside the container, on a single host without the `--wrap` option.

## Whitout the wrapper
With `GEN_SHARED_CVMFS` being the cache directory on the host, `BIND_LIST` the file system to be acces by genpipes, {IMAGE_PATH}/genpipes.sif the [latest sif file released](https://github.com/c3g/genpipes_in_a_container/releases/latest). 
```
 singularity run --cleanenv -S /var/run/cvmfs -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
    -B "$BIND_LIST" \
    --fusemount \
      "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
    --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
    --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
    ${IMAGE_PATH}/genpipes.sif "$@"
```

