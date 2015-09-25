# brewbus

This is a very simple shell script that outputs Omnibus-style OS X installer packages from Homebrew.

The use case is for outputting Installer packages for a given Homebrew formula, including all its dependencies,
in such a way that the binary and dependencies can't collide with those of other components (other formulae,
other things installed in `/usr/local`, etc.)

If the formula and its dependencies are all versioned, it should be possible to make reproducible
builds of older versions by passing in the commit revision, which will build from the revision
within the Homebrew repo.

More on the general idea of Omnibus packaging here:

  * https://github.com/chef/omnibus
  * http://blog.scoutapp.com/articles/2013/06/21/omnibus-tutorial-package-a-standalone-ruby-gem

## How it works

Sets up an "isolated" Homebrew installation at a prefix you specify (e.g. `/myorg`), with the entire
formula installation located within the formula name (e.g. `/myorg/ffmpeg`). All the formula's
dependencies should be properly installed using `/myorg/ffmpeg` as the prefix, and an installer
package will 

```
sudo FORMULA=nyancat ./make_brew_omnibus_osx_pkg.sh
```

## Command-line options

There are none - all configuration is done via environment variables. This was done simply so that I could run the script standalone in a "cleanroom" VM as a Jenkins parameterized build (where the parameters ultimately set environment variables).

The supported environment variables for configuration:

#### FORMULA

(required): name of Homebrew formula

#### PREFIX

Prefix to use in conjunction with FORMULA, to use as a root for the package. For example, a `PREFIX` of `/opt` and a `FORMULA` of `tree` will make a root of `/opt/tree`, meaning the final binaries will be in `/opt/tree/bin/` (or `sbin`, etc.). **Default:** /brewbus

#### REVERSE_DOMAIN

Reverse-domain-style prefix for the installer package identifier. **Default:** com.github.brewbus

#### BREW_GIT_SHA

Optional Git SHA-1 hash to which the Brew installation's HEAD will be checked out. Useful if you want to 'pin' to a specific known state for the Formula. **Default:** (none, and use the tip of master branch)

#### BREW_REPO_URL

Optional alternate URL for the Homebrew repo (for example, a path to a pre-existing local clone to avoid re-cloning fresh). **Default:** https://github.com/homebrew/homebrew

#### OUTPUT_DIR

Optional output directory for the built package. **Default:** Current working directory


## Paths

Of course, binaries that are installed to `/myprefix/formula/{bin,sbin}` will not be in a user's default `PATH`. This tool wasn't specifically intended for distributing tools for general use but rather infrastructure- or build-related tools. However, one can always add additional paths to files in `/etc/paths.d`, which shells on OS X should be sourcing to add to the end of a user's `PATH` at login. If anyone would like to submit an option to add something like this automatically, it would be welcome.

## A note on sudo and permissions

Assuming one is using prefixes like `/myorg/formula`, this script will require `sudo` in order for the script to have permission to write to the root volume to create the prefix, unless the prefix exists already and is writeable by the current user.

Running this script using `sudo` if there already exists a Homebrew installation for the regular user of the machine may result in some cache files created as root, causing issues with future usage of `brew` as the regular user.

I don't advise running this in such a situation, but instead recommend it be done in a "clean" environment with no pre-existing Homebrew installation.
