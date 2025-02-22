# GenPipes in a container

You can use GenPipes in a Container (GiaC) to run GenPipes on a single machine, on a Torque/PBS cluster or on a SLURM cluster.

If Singularity/Docker is installed on your LINUX machine you are all set, a simple user with no special privilege is enough (no sudo needed).

While you can use (GiaC) to debug GenPipes on your laptop, [GenPipes](https://bitbucket.org/mugqic/genpipes/src/master/README.md) is design to run analysis on Super Computers.

## Install a compatible container technology on your machine

Follow installation procedure from the [Apptainer install page](https://apptainer.org/docs/user/latest/quick_start.html#installation) or the [Docker install page](https://docs.docker.com/get-docker/).

## What exactly is available in that container?

The full tested and integrated C3G/MUGQIC software stack: a complete set of genomics references and bioinformatics software; [for more details](http://www.computationalgenomics.ca/cvmfs-modules/).

## Setup a GiaC environment

You can use this container to test new version of GenPipes. The following documentation is written to install GenPipes 6 and above.

First, clone GenPipes and install it:

```bash
git clone --branch <GENPIPES_VERSION> https://bitbucket.org/mugqic/genpipes genpipes-<GENPIPES_VERSION>
cd genpipes-<GENPIPES_VERSION>
pip install .
```

If you prefer to have a virtual environment for GenPipes:

```bash
git clone --branch <GENPIPES_VERSION> https://bitbucket.org/mugqic/genpipes genpipes-<GENPIPES_VERSION>
cd genpipes-<GENPIPES_VERSION>
python3 -m venv .genpipes_venv
source .genpipes_venv/bin/activate
pip install .
```

Then, install the wrapper:
```bash
genpipes tools get_wrapper
```

You can now configure the `genpipes/resources/container/etc/wrapper.conf` file:

```bash
# GENPIPES_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GENPIPES_SHARED_CVMFS=$HOME/cvmfs
BIND_LIST=
GENPIPES_CONTAINERTYPE=apptainer
GENPIPES_VERSION=
GENPIPES_DIR=
```

`GENPIPES_SHARED_CVMFS` will hold a cache for GiaC [CVMFS](https://cernvm.cern.ch/portal/filesystem) system, it will hold the genomes and software being used by GenPipes. This folder will grow with GenPipes usage. You can delete it in between usage, but keep in mind that once deleted it will need to be rebuild by downloading data form the internet.

`BIND_LIST` is a list of file system, separated by comma, you need GenPipes to have access to, by default, only your $HOME is mounted. For example if you are on an HPC system with a `/scratch` and `/data` space, you would have `BIND_LIST=/scratch,/data`. The string will be fed to Singularity `--bind` option, see `apptainer --help` for more details.

`GENPIPES_CONTAINERTYPE` is the container to use, either `apptainer` (default), `singularity`, `docker` or `podman`.

`GENPIPES_VERSION` is the version of GenPipes to use, by default the latest version is used. The version has to be released and installed in cvmfs. Make sure the version chosen is the same as the one you installed otherwise you might have unrecognized arguments or unexpected behavior. If you want to use the local installed version set it to `local`, see [Using a local GenPipes version](#using-a-local-genpipes-version) below. If you want to use a version below 5 see [GenPipes 4 in a Container](#genpipes-4-in-a-container). GenPipes 5 is not working with the container, use GenPipes 6 instead, or GenPipes 4 for deprecated pipelines.

`GENPIPES_DIR` is the directory where GenPipes is locally cloned. See [Using a local GenPipes version](#using-a-local-genpipes-version) below.

You do not need any other setup on your machine.

## GENPIPES USAGE

You will find GenPipes detailed documentation [here](https://genpipes.readthedocs.io/en/latest).

# On SLURM or PBS/torque HPC

[Read the GenPipes documentation](https://genpipes.readthedocs.io/en/latest/deploy/dep_gp_container.html), follow guidelines there to launch a GenPipes pipeline (from outside the container) and add the `--wrap` option so GenPipes will wrap all its command with the container instrumentation.

# On a single machine.
## With the wrapper
[Read the GenPipes documentation](https://genpipes.readthedocs.io/en/latest/deploy/dep_gp_container.html), follow guidelines there to launch a GenPipes pipeline and add the `--wrap`, `-j batch` and `--no-json` options. In that case you'll NOT use any scheduler system and GenPipes analysis might be longer.

You can also run the `genpipes/resources/container/bin/container_wrapper.sh` command to get inside the container with the right configuration. You will then have access to all the GenPipes tools be able to run them directly inside the container, on a single host WITHOUT the `--wrap` option.
To use a GenPipes version other than latest run `genpipes/resources/container/bin/container_wrapper.sh -V <VERSION>`.

## Without the wrapper
To use a GenPipes version other than latest add `-V <VERSION>` at the end of one of the command below. To test a cloned version, set `-V local` and mount the cloned directory with the right command. See detail in each section.

### Using Apptainer
With `GENPIPES_SHARED_CVMFS` being the cache directory on the host, `BIND_LIST` the file system to be accessed by GenPipes, {IMAGE_PATH}/genpipes.sif the [latest sif file released](https://github.com/c3g/genpipes_in_a_container/releases/latest). To use the cloned version, mount the directory with `-B ${GENPIPES_DIR}:/genpipes` option.
```bash
 apptainer run \
  --cleanenv \
  -S /var/run/cvmfs \
  -B ${GENPIPES_SHARED_CVMFS}:/cvmfs-cache \
  -B "$BIND_LIST" \
  --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
  --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
  --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
  ${IMAGE_PATH}/genpipes.sif
```
### Using Singularity
With `GENPIPES_SHARED_CVMFS` being the cache directory on the host, `BIND_LIST` the file system to be accessed by GenPipes, {IMAGE_PATH}/genpipes.sif the [latest sif file released](https://github.com/c3g/genpipes_in_a_container/releases/latest). To use the cloned version, mount the directory with `-B ${GENPIPES_DIR}:/genpipes` option.
```bash
 singularity run \
  --cleanenv \
  -S /var/run/cvmfs \
  -B ${GENPIPES_SHARED_CVMFS}:/cvmfs-cache \
  -B "$BIND_LIST" \
  --fusemount "container:cvmfs2 cvmfs-config.computecanada.ca /cvmfs/cvmfs-config.computecanada.ca" \
  --fusemount "container:cvmfs2 soft.mugqic /cvmfs/soft.mugqic"   \
  --fusemount "container:cvmfs2 ref.mugqic /cvmfs/ref.mugqic" \
  ${IMAGE_PATH}/genpipes.sif
```
### Using Docker
With `GENPIPES_SHARED_CVMFS` being the cache directory on the host and `BIND_LIST` the file system to be accessed by GenPipes. To use the cloned version, mount the directory with `--mount type=bind,source=${GENPIPES_DIR},target=/genpipes` option.
```bash
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
  --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache \
  ghcr.io/c3g/genpipes_in_a_container:latest
```
### Using Podman
With `GENPIPES_SHARED_CVMFS` being the cache directory on the host and `BIND_LIST` the file system to be accessed by GenPipes. WARNING: Not supported on Mac OS X yet. To use the cloned version, mount the directory with `--mount type=bind,source=${GENPIPES_DIR},target=/genpipes,Z` option.
```bash
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

# Using a local GenPipes version

If you want to use a local GenPipes version, you can use the `GENPIPES_DIR` variable in the `wrapper.conf` file. This variable should point to the directory where GenPipes is installed. The `GENPIPES_VERSION` variable should be left empty.

```bash
# GENPIPES_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GENPIPES_SHARED_CVMFS=$HOME/cvmfs
BIND_LIST=
GENPIPES_CONTAINERTYPE=apptainer
GENPIPES_VERSION=local
GENPIPES_DIR=path/to/genpipes-<GENPIPES_VERSION>
```


# GenPipes 4 in a Container

Assuming you have cloned GenPipes 6 or above and installed it following instructions above, you can still use GenPipes 4 in a Container. You have to checkout into the GenPipes 4 version you need and then use the `GENPIPES_VERSION` variable in the `wrapper.conf` file.
Here is an example with GenPipes 4.6.1 version:

```bash
# Change from the cloned released version to version 4.6.1
git checkout 4.6.1
# GENPIPES_VERSION being the initial clone here
export MUGQIC_GENPIPESS_HOME=path/to/genpipes-<GENPIPES_VERSION>
```
Then edit the `wrapper.conf` file to have:
```bash
# GENPIPES_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GENPIPES_SHARED_CVMFS=$HOME/cvmfs
BIND_LIST=
GENPIPES_CONTAINERTYPE=apptainer
GENPIPES_VERSION=4.6.1
```
And then you can run GenPipes 4.6.1 with the `--wrap` option and with all GenPipes 4.6.1 options. For example with SLURM and ampliconseq pipeline:
```bash
$MUGQIC_GENPIPESS_HOME/pipelines/ampliconseq/ampliconseq.py -j slurm -r readset.ampliconseq.txt -d design.ampliconseq.txt -c $MUGQIC_GENPIPESS_HOME/pipelines/ampliconseq/ampliconseq.base.ini $MUGQIC_GENPIPESS_HOME/pipelines/common_ini/<cluster>.ini --genpipes_file ampliconseq.sh --wrap
```
Once the GenPipes file `ampliconseq.sh` is written you can execute it `bash ampliconseq.sh` and all you individual job will be wrapped in the container.
