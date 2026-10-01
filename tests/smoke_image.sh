#!/bin/bash
# Smoke test of a GiaC image with Docker: CVMFS mounts with a host cache, GenPipes loads, versions are reported.
# Needs Docker, /dev/fuse and outbound HTTP to the CVMFS servers.
# Usage: tests/smoke_image.sh <image> [expected GiaC version]
#   e.g. tests/smoke_image.sh ghcr.io/c3g/genpipes_in_a_container:v4.1.0 v4.1.0

IMAGE=$1
EXPECTED_GIAC_VERSION=${2:-}
# Released GenPipes versions used to test -V, override if they leave CVMFS
GENPIPES4_VERSION=${GENPIPES4_VERSION:-4.6.1}
GENPIPES6_VERSION=${GENPIPES6_VERSION:-6.1.1}
# A CVMFS failure is retried once, to tell a server hiccup from a broken image
RETRY_DELAY=${RETRY_DELAY:-30}

if [ -z "${IMAGE}" ]; then
  echo "Usage: $0 <image> [expected GiaC version]"
  exit 2
fi

CACHE_DIR=$(mktemp -d)
FAILED=0

# Runs the image with the README docker options and a host cache directory, output in OUT
run_image() {
  docker run --rm \
    --security-opt apparmor=unconfined \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --tmpfs /var/run/cvmfs:rw \
    --mount type=bind,source="${CACHE_DIR}",target=/cvmfs-cache \
    "${IMAGE}" "$@" 2>&1
}

# Like run_image, retried once if CVMFS did not mount
run_with_retry() {
  OUT=$(run_image "$@")
  if ! grep -q "mounted cvmfs on /cvmfs/soft.mugqic" <<< "${OUT}"; then
    echo "CVMFS did not mount, retrying in ${RETRY_DELAY}s. Output:"
    echo "${OUT}" | grep -i cvmfs | sed 's/^/  /'
    sleep "${RETRY_DELAY}"
    OUT=$(run_image "$@")
  fi
}

check() {
  local description=$1 pattern=$2
  if grep -qE "${pattern}" <<< "${OUT}"; then
    echo "ok   ${description}"
  else
    echo "FAIL ${description} (expected output matching: ${pattern})"
    FAILED=$((FAILED+1))
  fi
}

show_output_on_failure() {
  if [ "$1" -ne "${FAILED}" ]; then
    echo "----- output -----"
    echo "${OUT}"
    echo "------------------"
  fi
}

echo "== Default GenPipes version"
before=${FAILED}
run_with_retry 'genpipes --help | head -1; module -t list 2>&1 | grep genpipes'
for repo in cvmfs-config.computecanada.ca ref.mugqic soft.mugqic; do
  check "CVMFS ${repo} mounted" "mounted cvmfs on /cvmfs/${repo}"
done
check "startup line with default version" "^GiaC ${EXPECTED_GIAC_VERSION:-[^ ]+} - GenPipes [0-9]+\.[0-9]+\.[0-9]+ \(default from CVMFS\)"
check "genpipes runs" "^usage: genpipes"
show_output_on_failure "${before}"

if [ -n "$(ls -A "${CACHE_DIR}" 2>/dev/null)" ]; then
  echo "ok   host cache directory used"
else
  echo "FAIL host cache directory is empty"
  FAILED=$((FAILED+1))
fi

echo "== GenPipes ${GENPIPES6_VERSION} requested"
before=${FAILED}
run_with_retry -V "${GENPIPES6_VERSION}" 'module -t list 2>&1 | grep genpipes'
check "startup line with requested version" "^GiaC .* - GenPipes ${GENPIPES6_VERSION} \(requested\)"
check "module loaded" "mugqic/genpipes/${GENPIPES6_VERSION}"
show_output_on_failure "${before}"

echo "== GenPipes ${GENPIPES4_VERSION} requested"
before=${FAILED}
run_with_retry -V "${GENPIPES4_VERSION}" 'module -t list 2>&1 | grep -E "genpipes|python"'
check "module loaded" "mugqic/genpipes/${GENPIPES4_VERSION}"
check "GenPipes 4 python loaded" "mugqic/python/3\."
show_output_on_failure "${before}"

# The cache belongs to the container cvmfs user, it may not be removable without sudo
rm -rf "${CACHE_DIR}" 2>/dev/null

echo "${FAILED} failure(s)"
[ "${FAILED}" -eq 0 ]
