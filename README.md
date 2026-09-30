# GenPipes in a container

You can use GenPipes in a Container (GiaC) to run GenPipes on a single machine, on a Torque/PBS cluster or on a SLURM cluster.

If Singularity/Docker is installed on your LINUX machine you are all set, a simple user with no special privilege is enough (no sudo needed).

The software available in CVMFS is built for x86-64 only. GiaC works on x86-64 Linux and on macOS with Docker Desktop (tested on Apple silicon with Rosetta enabled). It does not work on arm64 Linux (e.g. AWS Graviton or an arm64 virtual machine).

The container downloads the CVMFS data itself, so the machine needs outbound plain HTTP access (ports 80 and 8000) to the CVMFS servers. Sites where this access is only possible through a proxy are not supported yet. On such a machine, CVMFS fails with `Failed to initialize root file catalog`.

While you can use (GiaC) to debug GenPipes on your laptop, [GenPipes](https://github.com/c3g/GenPipes/blob/main/README.md) is design to run analysis on Super Computers.

## Install a compatible container technology on your machine

Follow installation procedure from the [Apptainer install page](https://apptainer.org/docs/user/latest/quick_start.html#installation) or the [Docker install page](https://docs.docker.com/get-docker/).

When using Docker on macOS, containers run inside a Linux virtual machine. An intermittent issue has been observed affecting CVMFS/FUSE initialization when using certain Docker Desktop virtualization and file system configurations.

This issue can be mitigated by using:
* Apple Virtualization Framework as the Virtual Machine Manager (VMM)
* gRPC FUSE as the file sharing implementation

These settings can be configured in Docker Desktop under:

`Settings > Virtual Machine Options`

<img width="2756" height="1458" alt="Docker_config" src="https://github.com/user-attachments/assets/90155c69-964b-49ba-9020-ec9ab9fd0c22" />

## What exactly is available in that container?

A collection of bioinformatics software modules available under `/cvmfs/soft.mugqic`. It also includes a set of genomic references and test data, available under `/cvmfs/ref.mugqic`.

## Setup a GiaC environment

You can use this container to test new version of GenPipes. The following documentation is written to install GenPipes 6 and above.

First, clone GenPipes and install it:

```bash
git clone --branch <GENPIPES_VERSION> https://github.com/c3g/GenPipes.git genpipes-<GENPIPES_VERSION>
cd genpipes-<GENPIPES_VERSION>
pip install .
```

If you prefer to have a virtual environment for GenPipes:

```bash
git clone --branch <GENPIPES_VERSION> https://github.com/c3g/GenPipes.git genpipes-<GENPIPES_VERSION>
cd genpipes-<GENPIPES_VERSION>
python3 -m venv .genpipes_venv
source .genpipes_venv/bin/activate
pip install .
```

Then, install the wrapper:
```bash
genpipes tools get_wrapper
```

The wrapper is installed in a `resources/container` folder next to the installed `genpipes` package: in `site-packages` with `pip install .`, or at the root of the clone with `pip install -e .`. To find it:

```bash
GIAC_DIR=$(python3 -c "import genpipes, os; print(os.path.join(os.path.dirname(os.path.dirname(genpipes.__file__)), 'resources', 'container'))")
echo $GIAC_DIR
```

You can now configure the `$GIAC_DIR/etc/wrapper.conf` file:

```bash
# GENPIPES_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GENPIPES_SHARED_CVMFS=$HOME/cvmfs
BIND_LIST=
GENPIPES_CONTAINERTYPE=apptainer
GENPIPES_VERSION=
GENPIPES_DIR=
```

`GENPIPES_SHARED_CVMFS` will hold a cache for GiaC [CVMFS](https://cernvm.cern.ch/portal/filesystem) system, it will hold the genomes and software being used by GenPipes. This folder will grow with GenPipes usage. You can delete it in between usage, but keep in mind that once deleted it will need to be rebuild by downloading data form the internet. With Docker or Podman on Linux, the cache files belong to the container `cvmfs` user, so you need `sudo` to delete them.

`BIND_LIST` is a list of file system, separated by comma, you need GenPipes to have access to, by default, only your $HOME is mounted. For example if you are on an HPC system with a `/scratch` and `/data` space, you would have `BIND_LIST=/scratch,/data`. The string will be fed to Singularity `--bind` option, see `apptainer --help` for more details. With Docker or Podman, each path is mounted with its own `--mount` option.

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

You can also run the `$GIAC_DIR/bin/container_wrapper.sh` command to get inside the container with the right configuration. You will then have access to all the GenPipes tools be able to run them directly inside the container, on a single host WITHOUT the `--wrap` option.
To use a GenPipes version other than latest run `$GIAC_DIR/bin/container_wrapper.sh -V <VERSION>`.

## Without the wrapper
To use a GenPipes version other than latest add `-V <VERSION>` at the end of one of the command below. To test a cloned version, set `-V local` and mount the cloned directory with the right command. See detail in each section.

The commands below read `GENPIPES_SHARED_CVMFS` and `BIND_LIST` from your shell, not from `wrapper.conf`. Set them and create the cache directory first:

```bash
# GENPIPES_SHARED_CVMFS should have a sufficient amount of space to load full reference files
export GENPIPES_SHARED_CVMFS=$HOME/cvmfs
export BIND_LIST=/scratch,/data
mkdir -p ${GENPIPES_SHARED_CVMFS}
```

If `GENPIPES_SHARED_CVMFS` is not set, CVMFS fails with `cannot create workspace directory /cvmfs-cache/...` and GenPipes is not available in the container.

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
With `GENPIPES_SHARED_CVMFS` being the cache directory on the host and `BIND_LIST` the file system to be accessed by GenPipes (one path, add one `--mount` option per extra path). To use the cloned version, mount the directory with `--mount type=bind,source=${GENPIPES_DIR},target=/genpipes` option. The `--security-opt apparmor=unconfined` option is needed on hosts using AppArmor (e.g. Ubuntu), because the default Docker AppArmor profile blocks the CVMFS mount.
```bash
docker run \
  -it \
  --security-opt apparmor=unconfined \
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
With `GENPIPES_SHARED_CVMFS` being the cache directory on the host and `BIND_LIST` the file system to be accessed by GenPipes (one path, add one `--mount` option per extra path). WARNING: Not supported on Mac OS X yet. To use the cloned version, mount the directory with `--mount type=bind,source=${GENPIPES_DIR},target=/genpipes,Z` option.
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
  --mount type=bind,source=${GENPIPES_SHARED_CVMFS},target=/cvmfs-cache,Z \
  ghcr.io/c3g/genpipes_in_a_container:latest
```

# Using a local GenPipes version

If you want to use a local GenPipes version, you can use the `GENPIPES_DIR` variable in the `wrapper.conf` file. This variable should point to the directory where GenPipes is installed. The `GENPIPES_VERSION` variable should be set to `local`, an empty value uses the latest released version.

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
