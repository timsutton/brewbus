#!/bin/sh -e
#
# brewbus.sh
# Copyright Tim Sutton, 2014-2015
#
# Dead-simple Omnibus-style installer package builder for OS X using Homebrew. It
# takes no command-line options or arguments: all configuration is done using
# environment variables:
#
# - FORMULA:        (required) name of Homebrew formula
# - PREFIX:         prefix to use in conjunction with FORMULA, to use as a root for the package.
#                   For example, a PREFIX of "/opt" and a FORMULA of "tree" will make a root of 
#                   /opt/tree, meaning the final binaries will be in /opt/tree/bin/ (or sbin, etc.)
#                   default: /brewbus
# - REVERSE_DOMAIN: reverse-domain-style prefix for the installer package identifier
#                   default: com.github.brewbus
# - BREW_GIT_SHA:   optional Git SHA-1 hash to which the Brew installation's HEAD will
#                   be checked out. Useful if you want to 'pin' to a specific known state
#                   for the Formula.
#                   default: (none, use the tip of master branch)
# - BREW_REPO_URL:  optional alternate URL for the Homebrew repo (for example, a path to a
#                   pre-existing local clone)
#                   default: https://github.com/homebrew/homebrew
# - OUTPUT_DIR:     optional output directory for the built package
#                   default: (current working directory)

FORMULA=${FORMULA:-""}
PREFIX=${PREFIX:-"/brewbus"}
REVERSE_DOMAIN=${REVERSE_DOMAIN:-"com.github.brewbus"}
BREW_GIT_SHA=${BREW_GIT_SHA:-""}
BREW_REPO_URL=${BREW_REPO_URL:-"https://github.com/homebrew/homebrew"}
OUTPUT_DIR=${OUTPUT_DIR:-"$(pwd)"}

if [ -z "${FORMULA}" ]; then
    echo "FORMULA must be defined as an environment variable to this script." 1>&2
    exit 1
fi
# Clear any existing formula prefix and install Homebrew to this as our "root"
root="${PREFIX}/${FORMULA}"
[ -d "${root}" ] && rm -rf "${root}"
git clone "${BREW_REPO_URL}" "${root}"
cd "${root}"

# Optionally revert to BREW_GIT_SHA
if [ -n "${BREW_GIT_SHA}" ]; then
    git checkout "${BREW_GIT_SHA}"
fi

# Brew install $FORMULA, figure out what version was installed
bin/brew install "${FORMULA}"
version_path="${root}/Cellar/${FORMULA}"
version=$(ls "${version_path}")
if [ -z "${version}" ]; then
    echo "Could not derive version directory expected at path: ${version_path}" 1>&2
    exit 1
fi

# Build a package using our root, with the same path as the install destination.
# Includes a short list of exclude filters, which should leave Cellar and the
# LSB directories.
# This pkgbuild filter list was tailored for exactly one formula: wimlib,
# so it's likely there are things missing or that eventually it will need to be
# updated to follow Homebrew.
pkgbuild \
    --version "${version}" \
    --identifier "${REVERSE_DOMAIN}.${FORMULA}" \
    --root "${root}" \
    --install-location "${root}" \
    --filter '/.git.*$' \
    --filter '/.yardopts' \
    --filter '/.*.md$' \
    --filter '/.*.txt$' \
    --filter '/Library$' \
    --filter '/bin/brew' \
    --filter '/share/doc/homebrew' \
    --filter '/share/man/man1/brew.1' \
    --filter '/.travis.yml' \
    "${OUTPUT_DIR}/${FORMULA}-${version}.pkg"
