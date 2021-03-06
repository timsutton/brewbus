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
package will be built using the prefix as the `install-location`. The payload is the entire contents of the Homebrew installation, minus a set of Homebrew-specific paths which are excluded from the built package (such as the actual repo in `.git`).

```
FORMULA=nyancat ./brewbus.sh
```

To create the initial prefix/formula path, this script uses `sudo` so that your regular (or admin) user can create the necessarily target directories, but the actual brew installation and package creation is done as a regular user. Homebrew also, rightfully, doesn't allow being run as root.

## Command-line options

There are none - all configuration is done via environment variables. This was done simply so that I could run the script standalone in a "cleanroom" VM as a Jenkins parameterized build (where the parameters ultimately set environment variables).

The supported environment variables for configuration:

#### FORMULA

(required): name of Homebrew formula

#### PREFIX

Prefix to use in conjunction with FORMULA, to use as a root for the package. For example, a `PREFIX` of `/opt` and a `FORMULA` of `tree` will make a root of `/opt/tree`, meaning the final binaries will be in `/opt/tree/bin/` (or `sbin`, etc.). **Default:** /brewbus

#### REVERSE_DOMAIN

Reverse-domain-style prefix for the installer package identifier. **Default:** ca.macops.brewbus

#### BREW_GIT_SHA

Optional Git SHA-1 hash to which the tap of the homebrew-core repo will be checked out. Useful if you want to 'pin' to a specific known state for the Formula. **Default:** (none, and use the tip of master branch)

#### OUTPUT_DIR

Optional output directory for the built package. **Default:** Current working directory


## Paths

Of course, binaries that are installed to `/myprefix/formula/{bin,sbin}` will not be in a user's default `PATH`. This tool wasn't specifically intended for distributing tools for general use but rather infrastructure- or build-related tools. However, one can always add additional paths to files in `/etc/paths.d`, which shells on OS X should be sourcing to add to the end of a user's `PATH` at login. If anyone would like to submit an option to add something like this automatically, it would be welcome.

## Formulae linking to /usr/local/opt

Some formulae link to shared libraries installed to /usr/local/opt (for example, formulae depending on `openssl`), and those will not work with this project as-is. The workaround for these cases would be to manage installations of these dependencies to /usr/local/opt independently. Not yet sure if there is a way to also support installing these dependencies within the same PREFIX as we install the rest of the formula dependencies.

## A note on sudo and permissions

Assuming one is using prefixes like `/myorg/formula`, this script will require `sudo` in order for the script to have permission to write to the root volume to create the prefix, unless the prefix exists already and is writeable by the current user.

Running this script using `sudo` if there already exists a Homebrew installation for the regular user of the machine may result in some cache files created as root, causing issues with future usage of `brew` as the regular user.

I don't advise running this in such a situation, but instead recommend it be done in a "clean" environment with no pre-existing Homebrew installation.
