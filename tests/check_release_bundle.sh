#!/bin/bash
# Checks a release wrapper_genpipes.tgz before it is uploaded.
# Usage: tests/check_release_bundle.sh <wrapper_genpipes.tgz> <release tag>
#   e.g. tests/check_release_bundle.sh container/wrapper_genpipes.tgz v4.1.0

BUNDLE=$1
TAG=$2
IMAGE=${IMAGE:-ghcr.io/c3g/genpipes_in_a_container}

if [ -z "${BUNDLE}" ] || [ -z "${TAG}" ]; then
  echo "Usage: $0 <wrapper_genpipes.tgz> <release tag>"
  exit 2
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT
FAILED=0

check() {
  local description=$1
  shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   ${description}"
  else
    echo "FAIL ${description}"
    FAILED=$((FAILED+1))
  fi
}

tar -xzf "${BUNDLE}" -C "${WORK_DIR}" || { echo "FAIL cannot extract ${BUNDLE}"; exit 1; }
DIR=${WORK_DIR}/wrapper_genpipes

check "wrapper is executable" test -x "${DIR}/bin/container_wrapper.sh"
check "wrapper.conf template present" test -f "${DIR}/etc/wrapper.conf.tpl"
check "wrapper pinned to ${IMAGE}:${TAG}" grep -qx "GIAC_IMAGE=${IMAGE}:${TAG}" "${DIR}/bin/container_wrapper.sh"
check "images/genpipes-${TAG}.sif present" test -s "${DIR}/images/genpipes-${TAG}.sif"
check "images/genpipes.sif points to genpipes-${TAG}.sif" test "$(readlink "${DIR}/images/genpipes.sif")" = "genpipes-${TAG}.sif"

# The sif carries the GiaC version, checked without starting CVMFS
if command -v apptainer >/dev/null 2>&1; then
  # The runner may not allow apptainer to start a container: skip rather than fail the release for it
  if apptainer exec "${DIR}/images/genpipes-${TAG}.sif" true >/dev/null 2>&1; then
    SIF_VERSION=$(apptainer exec "${DIR}/images/genpipes-${TAG}.sif" printenv GIAC_VERSION 2>/dev/null)
    check "sif GIAC_VERSION is ${TAG} (found '${SIF_VERSION}')" test "${SIF_VERSION}" = "${TAG}"
  else
    echo "skip sif GIAC_VERSION check, apptainer cannot start a container here"
  fi
else
  echo "skip sif GIAC_VERSION check, apptainer not found"
fi

echo "${FAILED} failure(s)"
[ "${FAILED}" -eq 0 ]
