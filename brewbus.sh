#!/bin/bash -e
#
# brewbus.sh
# Copyright Tim Sutton, 2014-2018
#
# Dead-simple Omnibus-style installer package builder for macOS using Homebrew. It
# takes no command-line options or arguments: all configuration is done using
# environment variables. Please see the README.md for details on these configuration
# variables.

FORMULA=${FORMULA:-""}
PREFIX=${PREFIX:-"/brewbus"}
REVERSE_DOMAIN=${REVERSE_DOMAIN:-"ca.macops.brewbus"}
BREW_GIT_SHA=${BREW_GIT_SHA:-""}
BREW_REPO_URL=${BREW_REPO_URL:-"https://github.com/homebrew/homebrew"}
OUTPUT_DIR=${OUTPUT_DIR:-"$(pwd)"}

if [ -z "${FORMULA}" ]; then
    echo "FORMULA must be defined as an environment variable to this script." 1>&2
    exit 1
fi

if [[ $UID == "0" ]]; then
	echo "This script won't work if you're running it directly with sudo"
	exit 1
fi

# Clear any existing formula prefix and install Homebrew to this as our "root"
root="${PREFIX}/${FORMULA}"
[ -d "${root}" ] && sudo rm -rf "${root}"
sudo mkdir -p "${root}"
sudo chown -R "$(whoami)" "${root}"

# Just doing a shallow clone of the installer for now, later see how
# we might still support pinning to a specific SHA in the homebrew-core tap
# git clone "${BREW_REPO_URL}" "${root}"
cd "${root}"
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1

# TODO: not working yet as long as we're downloading a simple tarball
# # Optionally revert to BREW_GIT_SHA
# if [ -n "${BREW_GIT_SHA}" ]; then
#     git checkout "${BREW_GIT_SHA}"
# fi

# Brew install $FORMULA, figure out what version was installed
bin/brew install --verbose "${FORMULA}"
version_path="${root}/Cellar/${FORMULA}"
version=$(ls "${version_path}")
if [ -z "${version}" ]; then
    echo "Could not derive version directory expected at path: ${version_path}" 1>&2
    exit 1
fi

# Build a package using our root, with the same path as the install destination.
# Includes a short list of exclude filters, which should leave Cellar and the
# LSB directories.
# It's likely there are things missing here, and certainly it will need to be
# updated going forward to follow Homebrew.
pkgbuild \
    --version "${version}" \
    --identifier "${REVERSE_DOMAIN}.${FORMULA}" \
    --root "${root}" \
    --install-location "${root}" \
    --filter '.DS_Store' \
    --filter '/.git.*$' \
    --filter '/.yardopts' \
    --filter '/.*.md$' \
    --filter '/.*.txt$' \
    --filter '/Library$' \
    --filter '/bin/brew' \
    --filter '/completions' \
    --filter '/docs' \
    --filter '/etc/bash_completion.d' \
    --filter '/manpages/brew.*\.1' \
    --filter '/share/doc/homebrew' \
    --filter '/share/man/man1/brew.*\.1' \
    --filter '/share/zsh' \
    --filter '/var/homebrew' \
    --filter '/.travis.yml' \
    "${OUTPUT_DIR}/${FORMULA}-${version}.pkg"
