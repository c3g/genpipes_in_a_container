#!/bin/bash
# Tests the command lines built by container_wrapper.sh, without running any container.
# docker, podman, apptainer and singularity are replaced by stubs that print their arguments.
# Usage: tests/test_wrapper.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER_SRC=${REPO_DIR}/container/wrapper_genpipes/bin/container_wrapper.sh
TEMPLATE=${REPO_DIR}/container/wrapper_genpipes/etc/wrapper.conf.tpl

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT

FAILED=0
PASSED=0

# Stub container runtimes: print the runtime name and one argument per line
STUB_DIR=${WORK_DIR}/stubs
mkdir -p "${STUB_DIR}"
for runtime in docker podman apptainer singularity; do
  cat > "${STUB_DIR}/${runtime}" <<EOF
#!/bin/bash
echo "RUNTIME=${runtime}"
for arg in "\$@"; do echo "ARG=\${arg}"; done
EOF
  chmod +x "${STUB_DIR}/${runtime}"
done

# Runs the wrapper with the given wrapper.conf content, from RUN_DIR (default: $HOME), and stores its output in OUT
run_wrapper() {
  local conf=$1
  shift
  local case_dir=${WORK_DIR}/case
  rm -rf "${case_dir}"
  mkdir -p "${case_dir}/bin" "${case_dir}/etc" "${case_dir}/home"
  cp "${WRAPPER_SRC}" "${case_dir}/bin/container_wrapper.sh"
  printf '%s\n' "${conf}" > "${case_dir}/etc/wrapper.conf"
  OUT=$(cd "${RUN_DIR:-${case_dir}/home}" && HOME=${case_dir}/home PATH="${STUB_DIR}:${PATH}" bash "${case_dir}/bin/container_wrapper.sh" "$@" 2>&1)
  RC=$?
}

# Assertions on the last wrapper output
expect_arg() {
  if grep -qxF "ARG=$1" <<< "${OUT}"; then PASSED=$((PASSED+1)); else FAILED=$((FAILED+1)); echo "FAIL [${CASE}] missing argument: $1"; fi
}
expect_no_arg() {
  if grep -qxF "ARG=$1" <<< "${OUT}"; then FAILED=$((FAILED+1)); echo "FAIL [${CASE}] unexpected argument: $1"; else PASSED=$((PASSED+1)); fi
}
expect_no_match() {
  if grep -qE "$1" <<< "${OUT}"; then FAILED=$((FAILED+1)); echo "FAIL [${CASE}] unexpected output matching: $1"; else PASSED=$((PASSED+1)); fi
}
expect_count() {
  local count
  count=$(grep -cxF "ARG=$1" <<< "${OUT}")
  if [ "${count}" -eq "$2" ]; then PASSED=$((PASSED+1)); else FAILED=$((FAILED+1)); echo "FAIL [${CASE}] argument '$1' found ${count} times, expected $2"; fi
}
expect_runtime() {
  if grep -qxF "RUNTIME=$1" <<< "${OUT}"; then PASSED=$((PASSED+1)); else FAILED=$((FAILED+1)); echo "FAIL [${CASE}] $1 was not called"; fi
}
expect_rc() {
  if [ "${RC}" -eq "$1" ]; then PASSED=$((PASSED+1)); else FAILED=$((FAILED+1)); echo "FAIL [${CASE}] exit code ${RC}, expected $1"; fi
}

TEMPLATE_CONF=$(cat "${TEMPLATE}")
DEFAULT_IMAGE=ghcr.io/c3g/genpipes_in_a_container:latest

CASE="template ends with a newline"
if [ -z "$(tail -c1 "${TEMPLATE}")" ]; then PASSED=$((PASSED+1)); else FAILED=$((FAILED+1)); echo "FAIL [${CASE}]"; fi

for runtime in apptainer singularity; do
  CASE="${runtime}, template values"
  run_wrapper "${TEMPLATE_CONF/GENPIPES_CONTAINERTYPE=apptainer/GENPIPES_CONTAINERTYPE=${runtime}}"
  expect_rc 0
  expect_runtime "${runtime}"
  expect_arg "${WORK_DIR}/case/home/cvmfs:/cvmfs-cache"
  expect_no_arg ""
  expect_no_match "^ARG=GENPIPES_VERSION="
  expect_no_match ":/genpipes$"

  CASE="${runtime}, BIND_LIST, GENPIPES_VERSION and GENPIPES_DIR set"
  run_wrapper "$(printf '%s\n' "${TEMPLATE_CONF}" | sed -e "s#^GENPIPES_CONTAINERTYPE=.*#GENPIPES_CONTAINERTYPE=${runtime}#" -e 's#^BIND_LIST=.*#BIND_LIST=/scratch,/data#' -e 's#^GENPIPES_VERSION=.*#GENPIPES_VERSION=6.1.1#' -e 's#^GENPIPES_DIR=.*#GENPIPES_DIR=/src/genpipes#')"
  expect_arg "/scratch,/data"
  expect_arg "GENPIPES_VERSION=6.1.1"
  expect_arg "/src/genpipes:/genpipes"
done

for runtime in docker podman; do
  [ "${runtime}" = "podman" ] && Z=",Z" || Z=""

  CASE="${runtime}, template values"
  run_wrapper "${TEMPLATE_CONF/GENPIPES_CONTAINERTYPE=apptainer/GENPIPES_CONTAINERTYPE=${runtime}}"
  expect_rc 0
  expect_runtime "${runtime}"
  expect_arg "type=bind,source=${WORK_DIR}/case/home/cvmfs,target=/cvmfs-cache${Z}"
  expect_arg "${DEFAULT_IMAGE}"
  expect_no_match "source=,"
  expect_no_match "^ARG=GENPIPES_VERSION="
  expect_no_match "target=/genpipes"

  CASE="${runtime}, comma separated BIND_LIST"
  run_wrapper "${TEMPLATE_CONF/GENPIPES_CONTAINERTYPE=apptainer/GENPIPES_CONTAINERTYPE=${runtime}}"$'\n'"BIND_LIST=/scratch,/data"
  expect_arg "type=bind,source=/scratch,target=/scratch${Z}"
  expect_arg "type=bind,source=/data,target=/data${Z}"

  CASE="${runtime}, run from a directory in BIND_LIST"
  mkdir -p "${WORK_DIR}/rundir"
  RUN_DIR=${WORK_DIR}/rundir run_wrapper "${TEMPLATE_CONF/GENPIPES_CONTAINERTYPE=apptainer/GENPIPES_CONTAINERTYPE=${runtime}}"$'\n'"BIND_LIST=/scratch,${WORK_DIR}/rundir/"
  expect_arg "type=bind,source=/scratch,target=/scratch${Z}"
  expect_no_match "source=${WORK_DIR}/rundir/?,"
  expect_count "${WORK_DIR}/rundir:${WORK_DIR}/rundir" 1

  CASE="${runtime}, GENPIPES_VERSION, GENPIPES_DIR and GIAC_IMAGE set"
  run_wrapper "$(printf '%s\n' "${TEMPLATE_CONF}" | sed -e "s#^GENPIPES_CONTAINERTYPE=.*#GENPIPES_CONTAINERTYPE=${runtime}#" -e 's#^GENPIPES_VERSION=.*#GENPIPES_VERSION=6.1.1#' -e 's#^GENPIPES_DIR=.*#GENPIPES_DIR=/src/genpipes#')"$'\n'"GIAC_IMAGE=example.org/giac:test"
  expect_arg "GENPIPES_VERSION=6.1.1"
  expect_arg "type=bind,source=/src/genpipes,target=/genpipes${Z}"
  expect_arg "example.org/giac:test"
  expect_no_arg "${DEFAULT_IMAGE}"
done

CASE="docker, AppArmor option"
run_wrapper "${TEMPLATE_CONF/GENPIPES_CONTAINERTYPE=apptainer/GENPIPES_CONTAINERTYPE=docker}"
expect_arg "apparmor=unconfined"

CASE="former GEN_SHARED_CVMFS name"
run_wrapper "$(printf '%s\n' "${TEMPLATE_CONF}" | sed -e 's#GENPIPES_SHARED_CVMFS=.*#GEN_SHARED_CVMFS=/legacy/cvmfs#' -e 's#^GENPIPES_CONTAINERTYPE=.*#GENPIPES_CONTAINERTYPE=docker#')"
expect_arg "type=bind,source=/legacy/cvmfs,target=/cvmfs-cache"

CASE="arguments passed to the container"
run_wrapper "${TEMPLATE_CONF/GENPIPES_CONTAINERTYPE=apptainer/GENPIPES_CONTAINERTYPE=docker}" -V 6.1.1 "genpipes --help"
expect_arg "-V"
expect_arg "6.1.1"
expect_arg "genpipes --help"

CASE="unknown container type"
run_wrapper "${TEMPLATE_CONF/GENPIPES_CONTAINERTYPE=apptainer/GENPIPES_CONTAINERTYPE=lxc}"
expect_rc 1

echo "${PASSED} passed, ${FAILED} failed"
[ "${FAILED}" -eq 0 ]
