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

## Paths

Of course, binaries you install to `/myprefix/formula/{bin,sbin}` will not be in a user's default `PATH`. This tool wasn't specifically intended for distributing tools for general use but rather infrastructure- or build-related tools. However, one can always add additional paths to files in `/etc/paths.d`, which shells on OS X should be sourcing to add to the end of a user's `PATH` at login. If anyone would like to submit an option to add something like this automatically, it would be welcome.
