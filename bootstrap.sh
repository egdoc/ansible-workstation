#!/bin/bash
#
# Author: Egidio Docile
#
# Bootstrap system

set -o errexit
set -o pipefail
set -o nounset

BOOTSTRAP_TMPDIR="$(mktemp --directory)";
BOOTSTRAP_GIT_REPO="https://github.com/egdoc/ansible-workstation"
BOOTSTRAP_DESKTOP_ENVIRONMENT="gnome"
BOOTSTRAP_ANSIBLE_SKIP_TAGS=""

usage() {
cat << EOF >&2

$0 [-d DESKTOP_ENVIRONMENT] [-h] [-s SKIP_TAGS]
DESCRIPTION
    -d 'DESKTOP_ENVIRONMENT'
        The desktop environment to initialize

    -h
        Show this message and exit

    -s 'SKIP_TAGS'
        Comma-separated list of ansible tags to skip

EOF
}

while getopts "d:s:h" OPT; do
  case "${OPT}" in
    d) BOOTSTRAP_DESKTOP_ENVIRONMENT="${OPTARG}" ;;
    s) BOOTSTRAP_ANSIBLE_SKIP_TAGS="${OPTARG}" ;;
    h|*) usage; exit ;;
  esac
done

shift $((OPTIND-1))

readonly BOOTSTRAP_TMPDIR \
  BOOTSTRAP_GIT_REPO \
  BOOTSTRAP_DESKTOP_ENVIRONMENT \
  BOOTSTRAP_ANSIBLE_SKIP_TAGS

trap 'rm -rf "${BOOTSTRAP_TMPDIR}"' EXIT

echo "Installing packages (git,ansible)..." 2> /dev/null
sudo dnf install --quiet --assumeyes git ansible ansible-collection-community-general

echo "Cloning ansible-workstation repository..." >&2
git clone "${BOOTSTRAP_GIT_REPO}" "${BOOTSTRAP_TMPDIR}"

echo "Installing tasks dependencies..." >&2
ansible-galaxy install \
  -r "${BOOTSTRAP_TMPDIR}/requirements.yml" \
  -p "${BOOTSTRAP_TMPDIR}"

echo "Running ansible..." >&2
ansible-playbook \
  --ask-become-pass \
  --extra-vars desktop_environment="${BOOTSTRAP_DESKTOP_ENVIRONMENT}" \
  --skip-tags "${BOOTSTRAP_ANSIBLE_SKIP_TAGS}" \
  "${BOOTSTRAP_TMPDIR}/main.yml"