# node-build

[![Build Status](https://travis-ci.org/OiNutter/node-build.png?branch=master)](https://travis-ci.org/OiNutter/node-build)

node-build is an [nodenv](https://github.com/OiNutter/nodenv) plugin
that provides an `nodenv install` command to compile and install
different versions of Node on UNIX-like systems.

You can also use node-build without nodenv in environments where you
need precise control over Node version installation.


## Installation

### Installing as an nodenv plugin (recommended)

Installing node-build as an nodenv plugin will give you access to the
`nodenv install` command.

    git clone git://github.com/OiNutter/node-build.git ~/.nodenv/plugins/node-build

This will install the latest development version of node-build into
the `~/.nodenv/plugins/node-build` directory. From that directory, you
can check out a specific release tag. To update node-build, run `git
pull` to download the latest changes.

### Installing as a standalone program (advanced)

Installing node-build as a standalone program will give you access to
the `node-build` command for precise control over Node version
installation. If you have nodenv installed, you will also be able to
use the `nodenv install` command.

    git clone git://github.com/OiNutter/node-build.git
    cd node-build
    ./install.sh

This will install node-build into `/usr/local`. If you do not have
write permission to `/usr/local`, you will need to run `sudo
./install.sh` instead. You can install to a different prefix by
setting the `PREFIX` environment variable.

To update node-build after it has been installed, run `git pull` in
your cloned copy of the repository, then re-run the install script.

## Usage

### Using `nodenv install` with nodenv

To install a Node version for use with nodenv, run `nodenv install` with
the exact name of the version you want to install. For example,

    nodenv install 0.10.0

Node versions will be installed into a directory of the same name
under `~/.nodenv/versions`.

To see a list of all available Node versions, run `nodenv install --list`.
You may also tab-complete available Node
versions if your nodenv installation is properly configured.

### Using `node-build` standalone

If you have installed node-build as a standalone program, you can use
the `node-build` command to compile and install Node versions into
specific locations.

Run the `node-build` command with the exact name of the version you
want to install and the full path where you want to install it. For
example,

    node-build 0.10.0 ~/local/node-0.10.0

To see a list of all available Node versions, run `node-build
--definitions`.

Pass the `-v` or `--verbose` flag to `node-build` as the first
argument to see what's happening under the hood.

### Custom definitions

Both `nodenv install` and `node-build` accept a path to a custom
definition file in place of a version name. Custom definitions let you
develop and install versions of Node that are not yet supported by
node-build.

See the [node-build built-in
definitions](https://github.com/OiNutter/node-build/tree/master/share/node-build)
as a starting point for custom definition files.

### Special environment variables

You can set certain environment variables to control the build
process.

* `TMPDIR` sets the location where node-build stores temporary files.
* `NODE_BUILD_BUILD_PATH` sets the location in which sources are
  downloaded and built. By default, this is a subdirectory of
  `TMPDIR`.
* `NODE_BUILD_CACHE_PATH`, if set, specifies a directory to use for
  caching downloaded package files.
* `NODE_BUILD_MIRROR_URL` overrides the default mirror URL root to one
  of your choosing.
* `NODE_BUILD_SKIP_MIRROR`, if set, forces node-build to download
  packages from their original source URLs instead of using a mirror.
* `CC` sets the path to the C compiler.
* `CONFIGURE_OPTS` lets you pass additional options to `./configure`.
* `MAKE` lets you override the command to use for `make`. Useful for
  specifying GNU make (`gmake`) on some systems.
* `MAKE_OPTS` (or `MAKEOPTS`) lets you pass additional options to
  `make`.
* `NODE_CONFIGURE_OPTS` and `NODE_MAKE_OPTS` allow you to specify
  configure and make options for buildling MRI. These variables will
  be passed to Node only, not any dependent packages (e.g. libyaml).

### Checksum verification

If you have the `sha1`, `openssl`, or `sha1sum` tool installed,
node-build will automatically verify the SHA1 checksum of each
downloaded package before installing it.

Checksums are optional and specified as anchors on the package URL in
each definition. (All bundled definitions include checksums.)

### Package download mirrors

You can point node-build to another mirror by specifying the
`NODE_BUILD_MIRROR_URL` environment variable--useful if you'd like to
run your own local mirror, for example. Package mirror URLs are
constructed by joining this variable with the MD5 checksum of the
package file.

If you don't have a SHA1 program installed, node-build will skip the
download mirror and use official URLs instead. You can force
node-build to bypass the mirror by setting the
`NODE_BUILD_SKIP_MIRROR` environment variable.

### Package download caching

You can instruct node-build to keep a local cache of downloaded
package files by setting the `NODE_BUILD_CACHE_PATH` environment
variable. When set, package files will be kept in this directory after
the first successful download and reused by subsequent invocations of
`node-build` and `nodenv install`.

The `nodenv install` command defaults this path to `~/.nodenv/cache`, so
in most cases you can enable download caching simply by creating that
directory.

### Keeping the build directory after installation

Both `node-build` and `nodenv install` accept the `-k` or `--keep`
flag, which tells node-build to keep the downloaded source after
installation. This can be useful if you need to use `gdb` and
`memprof` with Node.

Source code will be kept in a parallel directory tree
`~/.nodenv/sources` when using `--keep` with the `nodenv install`
command. You should specify the location of the source code with the
`NODE_BUILD_BUILD_PATH` environment variable when using `--keep` with
`node-build`.

## Update available build versions

To grab the latest versions from the node website and generate version files for node-build to use
run the following command in the `tools` subdirectory of your node-build installation:

``` shell
node scraper.js
```

Feel free to commit and send a pull request with the updated versions.

## Getting Help

Please see the [node-build
wiki](https://github.com/OiNutter/node-build/wiki) for solutions to
common problems.

If you can't find an answer on the wiki, open an issue on the [issue
tracker](https://github.com/OiNutter/node-build/issues). Be sure to
include the full build log for build failures.

### Credits

Copied from [ruby-build](https://github.com/sstephenson/ruby-build) and modified to work for node.

### License

(The MIT License)

Copyright (c) 2013 Will McKenzie

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
