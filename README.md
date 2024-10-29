# GenPipes in a container

You can use GenPipes in a Container (GiaC) to run GenPipes on a single machine, on a Torque/PBS cluster or on a SLURM cluster.

If Singularity/Docker is installed on your LINUX machine you are all set, a simple user with no special privilege is enough (no sudo needed).

While you can use (GiaC) to debug GenPipes on your laptop, [GenPipes](https://bitbucket.org/mugqic/genpipes/src/master/README.md) is design to run analysis on Super Computers.

## Install a compatible container technology on your machine

Follow installation procedure from the [Apptainer install page](https://apptainer.org/docs/user/latest/quick_start.html#installation) or the [Docker install page](https://docs.docker.com/get-docker/).

You can also [Read the GenPipes documentation](https://genpipes.readthedocs.io/).

## What exactly is avalable in that container?

The full tested and integrated C3G/MUGQIC software stack: a complete set of genomics references and bioinformatics softwares. [For more details: http://www.computationalgenomics.ca/cvmfs-modules/](http://www.computationalgenomics.ca/cvmfs-modules/)

## Setup a GiaC environment

You can use this container to test new version of GenPipes.

First, clone GenPipes and then get the container wrapper:

```
git clone https://bitbucket.org/mugqic/genpipes

genpipes/resources/container/get_wrapper.sh

```

You can now configure the `genpipes/resources/container/etc/wrapper.conf` file:

```
# GEN_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GEN_SHARED_CVMFS=$HOME/cvmfs
BIND_LIST=
GEN_CONTAINERTYPE=apptainer
```

`GEN_SHARED_CVMFS` will hold a cache for GiaC [CVMFS](https://cernvm.cern.ch/portal/filesystem) system, it will hold the genomes and software being used by GenPipes. This folder will grow with GenPipes usage. You can delete it in between usage, but keep in mind that once deleted it will need to be rebuild by downloading data form the internet.

`BIND_LIST` is a list of file system, separated by comma, you need GenPipes to have access to, by default, only your $HOME is mounted. For example if you are on an HPC system with a `/scratch` and `/data` space, you would have `BIND_LIST=/scratch,/data`. The string will be fed to Singularity `--bind` option, see `apptainer --help` for more details.

`GEN_CONTAINERTYPE` is the container to use, either `apptainer` (default), `singularity`, `docker` or `podman`.

You do not need any other setup on your machine.

## PIPELINE USAGE

The GenPipes documentation page is here:
https://genpipes.readthedocs.io/

# On SLURM or PBS/torque HPC

[Read the GenPipes documentation](https://genpipes.readthedocs.io/), follow guidelines there to launch a GenPipes pipeline and add the `--wrap` option so GenPipes with wrap all its command with the container instrumentation.

# On a single machine.
## With the wrapper 
[Read the GenPipes documentation](https://genpipes.readthedocs.io/), follow guidelines there to launch a GenPipes pipeline and add the `--wrap`, `-j batch` and `--no-json` options.

You can also run the `genpipes/resources/container/bin/container_wrapper.sh` command to get inside the container with the right configuration. You will then have access to all the GenPipes tools be able to run them directly inside the container, on a single host without the `--wrap` option.

## Whitout the wrapper
### Using Apptainer
With `GEN_SHARED_CVMFS` being the cache directory on the host, `BIND_LIST` the file system to be accessed by genpipes, {IMAGE_PATH}/genpipes.sif the [latest sif file released](https://github.com/c3g/genpipes_in_a_container/releases/latest).
```
 apptainer run \
  --cleanenv \
  -S /var/run/cvmfs \
  -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
  -B "$BIND_LIST" \
  --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
  --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
  --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
  ${IMAGE_PATH}/genpipes.sif
```
### Using Singularity
With `GEN_SHARED_CVMFS` being the cache directory on the host, `BIND_LIST` the file system to be accessed by genpipes, {IMAGE_PATH}/genpipes.sif the [latest sif file released](https://github.com/c3g/genpipes_in_a_container/releases/latest).
```
 singularity run \
  --cleanenv \
  -S /var/run/cvmfs \
  -B ${GEN_SHARED_CVMFS}:/cvmfs-cache \
  -B "$BIND_LIST" \
  --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
  --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
  --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
  ${IMAGE_PATH}/genpipes.sif
```
### Using Docker
With `GEN_SHARED_CVMFS` being the cache directory on the host and `BIND_LIST` the file system to be accessed by genpipes.
```
docker run \
  -it \
  --env-file $HOME/.genpipes_env \
  --rm \
  --device /dev/fuse \
  --cap-add SYS_ADMIN \
  --tmpfs /var/run/cvmfs:rw \
  -w $PWD \
  -v $PWD:$PWD \
  --mount type=bind,source=${BIND_LIST},target=${BIND_LIST} \
  --mount type=bind,source=${GEN_SHARED_CVMFS},target=/cvmfs-cache \
  ghcr.io/c3g/genpipes_in_a_container:latest
```
### Using Podman
With `GEN_SHARED_CVMFS` being the cache directory on the host and `BIND_LIST` the file system to be accessed by genpipes. WARNING: Not supported on Mac OS X yet.
```
podman run \
  -it \
  --env-file $HOME/.genpipes_env \
  --rm \
  --device /dev/fuse \
  --cap-add SYS_ADMIN \
  --tmpfs /var/run/cvmfs:rw \
  -w $PWD \
  -v $PWD:$PWD \
  --mount type=bind,source=${BIND_LIST},target=${BIND_LIST},Z \
  --mount type=bind,source=$HOME/cvmfs,target=/cvmfs-cache,Z \
  ghcr.io/c3g/genpipes_in_a_container:latest
```