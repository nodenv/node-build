# node-build

[![Build Status](https://travis-ci.org/OiNutter/node-build.png?branch=master)](https://travis-ci.org/OiNutter/node-build)

node-build is an [nodenv](https://github.com/OiNutter/nodenv) plugin that
provides a `nodenv install` command to compile and install different versions
of Node on UNIX-like systems.

You can also use node-build without nodenv in environments where you need
precise control over Node version installation.

See the [list of releases](https://github.com/OiNutter/node-build/releases)
for changes in each version.


## Installation

### Installing as an nodenv plugin (recommended)

Installing node-build as a nodenv plugin will give you access to the `nodenv
install` command.

    git clone https://github.com/OiNutter/node-build.git $(nodenv root)/plugins/node-build

This will install the latest development version of node-build into the
`$(nodenv root)/plugins/node-build` directory. From that directory, you can
check out a specific release tag. To update node-build, run `git
pull` to download the latest changes.

### Installing as a standalone program (advanced)

Installing node-build as a standalone program will give you access to the
`node-build` command for precise control over Node version installation. If you
have nodenv installed, you will also be able to use the `nodenv install`
command.

    git clone https://github.com/OiNutter/node-build.git
    cd node-build
    ./install.sh

This will install node-build into `/usr/local`. If you do not have write
permission to `/usr/local`, you will need to run `sudo ./install.sh` instead.
You can install to a different prefix by setting the `PREFIX` environment
variable.

To update node-build after it has been installed, run `git pull` in your cloned
copy of the repository, then re-run the install script.

### Installing with Homebrew (for OS X users)

Mac OS X users can install node-build with the [Homebrew](http://brew.sh)
package manager. This will give you access to the `node-build` command. If you
have nodenv installed, you will also be able to use the `nodenv install`
command.

*This is the recommended method of installation if you installed nodenv with
Homebrew.*

    brew install node-build

## Usage

Before you begin, you should ensure that your build environment has the proper
system dependencies for compiling the wanted Node version (see Node's
[prerequisites][]). (This is unnecessary if you only intend to install
official binaries.)

[prerequisites]: https://github.com/nodejs/node#unix--macintosh

### Using `nodenv install` with nodenv

To install a Node version for use with nodenv, run `nodenv install` with the
exact name of the version you want to install. For example,

    nodenv install 4.2.1

Node versions will be installed into a directory of the same name under
`$(nodenv root)/versions`.

To see a list of all available Node versions, run `nodenv install --list`.  You
may also tab-complete available Node versions if your nodenv installation is
properly configured.

### Using `node-build` standalone

If you have installed node-build as a standalone program, you can use the
`node-build` command to compile and install Node versions into specific
locations.

Run the `node-build` command with the exact name of the version you want to
install and the full path where you want to install it. For example,

    node-build 4.2.1 ~/local/node-4.2.1

To see a list of all available Node versions, run `node-build --definitions`.

Pass the `-v` or `--verbose` flag to `node-build` as the first argument to see
what's happening under the hood.

### Custom definitions

Both `nodenv install` and `node-build` accept a path to a custom definition
file in place of a version name. Custom definitions let you develop and install
versions of Node that are not yet supported by node-build.

See the [node-build built-in definitions][definitions] as a starting point for
custom definition files.

[definitions]: https://github.com/OiNutter/node-build/tree/master/share/node-build

### Binaries

By default, node-build will attempt to match one of the precompiled binaries
to your platform. If there is a binary for your platform, it will install it
instead of compiling from source. To force compilation, pass the `-c` or
`--compile` flag.

### Special environment variables

You can set certain environment variables to control the build process.

* `TMPDIR` sets the location where node-build stores temporary files.
* `NODE_BUILD_BUILD_PATH` sets the location in which sources are downloaded and
  built. By default, this is a subdirectory of `TMPDIR`.
* `NODE_BUILD_CACHE_PATH`, if set, specifies a directory to use for caching
  downloaded package files.
* `NODE_BUILD_MIRROR_URL` overrides the default mirror URL root to one of your
  choosing.
* `NODE_BUILD_SKIP_MIRROR`, if set, forces node-build to download packages from
  their original source URLs instead of using a mirror.
* `NODE_BUILD_ROOT` overrides the default location from where build definitions
  in `share/node-build/` are looked up.
* `NODE_BUILD_DEFINITIONS` can be a list of colon-separated paths that get
  additionally searched when looking up build definitions.
* `CC` sets the path to the C compiler.
* `CONFIGURE_OPTS` lets you pass additional options to `./configure`.
* `MAKE` lets you override the command to use for `make`. Useful for specifying
  GNU make (`gmake`) on some systems.
* `MAKE_OPTS` (or `MAKEOPTS`) lets you pass additional options to `make`.
* `MAKE_INSTALL_OPTS` lets you pass additional options to `make install`.
* `NODE_CONFIGURE_OPTS`, `NODE_MAKE_OPTS` and `NODE_MAKE_INSTALL_OPTS` allow
  you to specify configure and make options for buildling Node. These variables
  will be passed to Node only, not any dependent packages (e.g. v8).

### Applying patches to Node before compiling

Both `nodenv install` and `node-build` support the `--patch` (`-p`) flag that
signals that a patch from stdin should be applied to Node or iojs
source code before the `./configure` and compilation steps.

Example usage:

```sh
# applying a single patch
$ nodenv install --patch 0.10.36 < /path/to/node.patch

# applying a patch from HTTP
$ nodenv install --patch 0.10.36 < <(curl -sSL http://git.io/node.patch)

# applying multiple patches
$ cat fix1.patch fix2.patch | nodenv install --patch 0.10.36
```

### Checksum verification

If you have the `shasum`, `openssl`, or `sha256sum` tool installed, node-build will
automatically verify the SHA2 checksum of each downloaded package before
installing it.

Checksums are optional and specified as anchors on the package URL in each
definition. (All bundled definitions include checksums.)

### Package download mirrors

You can point node-build to another mirror by specifying the
`NODE_BUILD_MIRROR_URL` environment variable--useful if you'd like to run your
own local mirror, for example. Package mirror URLs are constructed by joining
this variable with the SHA2 checksum of the package file.

If you don't have an SHA2 program installed, node-build will skip the download
mirror and use official URLs instead. You can force node-build to bypass the
mirror by setting the `NODE_BUILD_SKIP_MIRROR` environment variable.

### Package download caching

You can instruct node-build to keep a local cache of downloaded package files
by setting the `NODE_BUILD_CACHE_PATH` environment variable. When set, package
files will be kept in this directory after the first successful download and
reused by subsequent invocations of `node-build` and `nodenv install`.

The `nodenv install` command defaults this path to `$(nodenv root)/cache`, so
in most cases you can enable download caching simply by creating that
directory.

### Keeping the build directory after installation

Both `node-build` and `nodenv install` accept the `-k` or `--keep` flag, which
tells node-build to keep the downloaded source after installation. This can be
useful if you need to use `gdb` and `memprof` with Node.

Source code will be kept in a parallel directory tree `$(nodenv root)/sources`
when using `--keep` with the `nodenv install` command. You should specify the
location of the source code with the `NODE_BUILD_BUILD_PATH` environment
variable when using `--keep` with `node-build`.

## Update available build versions

To grab the latest versions from nodejs.org and generate definition files for
node-build to use, run the following command from node-build's directory:

``` shell
npm run write-definitions
```

Feel free to commit and send a pull request with the updated versions.

## Getting Help

Please see the [node-build wiki][wiki] for solutions to common problems.

[wiki]: https://github.com/OiNutter/node-build/wiki

If you can't find an answer on the wiki, open an issue on the [issue
tracker](https://github.com/OiNutter/node-build/issues). Be sure to include the
full build log for build failures.

### Credits

Copied from [ruby-build](https://github.com/sstephenson/ruby-build) and
modified to work for node.
