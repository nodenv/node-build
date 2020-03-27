# node-build

[![Test](https://github.com/nodenv/node-build/workflows/Test/badge.svg)](https://github.com/nodenv/node-build/actions?query=workflow%3ATest)

node-build is a command-line utility that makes it easy to install virtually any
version of Node, from source or precompiled binary.

It is available as a plugin for [nodenv][] that
provides the `nodenv install` command, or as a standalone program.

<!-- toc -->

- [Installation](#installation)
  * [Upgrading](#upgrading)
    + [Updating available build versions](#updating-available-build-versions)
- [Usage](#usage)
  * [Basic Usage](#basic-usage)
  * [Advanced Usage](#advanced-usage)
    + [Binaries](#binaries)
    + [Custom Build Definitions](#custom-build-definitions)
    + [Custom Build Configuration](#custom-build-configuration)
    + [Applying Patches](#applying-patches)
    + [Checksum Verification](#checksum-verification)
    + [Package Mirrors](#package-mirrors)
    + [Keeping the build directory after installation](#keeping-the-build-directory-after-installation)
    + [Retry installation without v/node-/node-v prefix](#retry-installation-without-vnode-node-v-prefix)
- [Getting Help](#getting-help)
- [Credits](#credits)

<!-- tocstop -->

## Installation

```sh
# Using Homebrew on macOS
$ brew install node-build

# As a nodenv plugin
$ mkdir -p "$(nodenv root)"/plugins
$ git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build

# As a standalone program
$ git clone https://github.com/nodenv/node-build.git
$ PREFIX=/usr/local ./node-build/install.sh
```

### Upgrading

```sh
# Via Homebrew
$ brew update && brew upgrade node-build

# As a nodenv plugin
$ git -C "$(nodenv root)"/plugins/node-build pull
```

#### Updating available build versions

To grab the latest versions from nodejs.org and generate definition files for
node-build to use, check out the [node-build-update-defs][] plugin.
Once installed:

``` shell
nodenv update-version-defs
```

No need to wait for node-build to provide the latest definitions!

## Usage

### Basic Usage

```sh
# As a nodenv plugin
$ nodenv install --list                    # lists all available versions of Node
$ nodenv install 10.13.0                   # installs Node 10.13.0 to ~/.nodenv/versions

# As a standalone program
$ node-build --definitions                 # lists all available versions of Node
$ node-build 10.13.0 ~/local/node-10.13.0  # installs Node 10.13.0 to ~/local/node-10.13.0
```

node-build does not check for system dependencies before downloading and
attempting to compile the Node source. Please ensure that [all requisite
libraries][build-env] are available on your system.

### Advanced Usage

#### Binaries

By default, node-build will attempt to match one of the precompiled binaries
to your platform. If there is a binary for your platform, it will install it
instead of compiling from source. To force compilation, pass the `-c` or
`--compile` flag.

#### Custom Build Definitions

If you wish to develop and install a version of Node that is not yet supported
by node-build, you may specify the path to a custom “build definition file” in
place of a Node version number.

Use the [default build definitions][definitions] as a template for your custom
definitions.

#### Custom Build Configuration

The build process may be configured through the following environment variables:

| Variable                 | Function                                                                                           |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| `TMPDIR`                 | Where temporary files are stored.                                                                  |
| `NODE_BUILD_BUILD_PATH`  | Where sources are downloaded and built. (Default: a timestamped subdirectory of `TMPDIR`)          |
| `NODE_BUILD_CACHE_PATH`  | Where to cache downloaded package files. (Default: `~/.nodenv/cache` if invoked as nodenv plugin)  |
| `NODE_BUILD_HTTP_CLIENT` | One of `aria2c`, `curl`, or `wget` to use for downloading. (Default: first one found in PATH)      |
| `NODE_BUILD_ARIA2_OPTS`  | Additional options to pass to `aria2c` for downloading.                                            |
| `NODE_BUILD_CURL_OPTS`   | Additional options to pass to `curl` for downloading.                                              |
| `NODE_BUILD_WGET_OPTS`   | Additional options to pass to `wget` for downloading.                                              |
| `NODE_BUILD_MIRROR_CMD`  | A command to construct the package mirror URL.                                                     |
| `NODE_BUILD_MIRROR_URL`  | Custom mirror URL root.                                                                            |
| `NODE_BUILD_SKIP_MIRROR` | Bypass the download mirror and fetch all package files from their original URLs.                   |
| `NODE_BUILD_ROOT`        | Custom build definition directory. (Default: `share/node-build`)                                   |
| `NODE_BUILD_DEFINITIONS` | Additional paths to search for build definitions. (Colon-separated list)                           |
| `CC`                     | Path to the C compiler.                                                                            |
| `NODE_CFLAGS`            | Additional `CFLAGS` options (_e.g.,_ to override `-O3`).                                           |
| `CONFIGURE_OPTS`         | Additional `./configure` options.                                                                  |
| `MAKE`                   | Custom `make` command (_e.g.,_ `gmake`).                                                           |
| `MAKE_OPTS` / `MAKEOPTS` | Additional `make` options.                                                                         |
| `MAKE_INSTALL_OPTS`      | Additional `make install` options.                                                                 |
| `NODE_CONFIGURE_OPTS`    | Additional `./configure` options (applies only to Node source).                                    |
| `NODE_MAKE_OPTS`         | Additional `make` options (applies only to Node source).                                           |
| `NODE_MAKE_INSTALL_OPTS` | Additional `make install` options (applies only to Node source).                                   |

#### Applying Patches

Both `nodenv install` and `node-build` support the `--patch` (`-p`) flag to apply
a patch to the Node (/iojs/chakracore) source code before building.
Patches are read from `STDIN`:

```sh
# applying a single patch
$ nodenv install --patch 11.1.0 < /path/to/node.patch

# applying a patch from HTTP
$ nodenv install --patch 11.1.0 < <(curl -sSL http://git.io/node.patch)

# applying multiple patches
$ cat fix1.patch fix2.patch | nodenv install --patch 11.1.0
```

#### Checksum Verification

If you have the `shasum`, `openssl`, or `sha256sum` tool installed, node-build will
automatically verify the SHA2 checksum of each downloaded package before
installing it.

Checksums are optional and specified as anchors on the package URL in each
definition. All definitions bundled with node-build include checksums.

#### Package Mirrors

By default, node-build downloads package files from the official URL specified in the definition file.

```sh
 # example:
 install_package "node-v12.0.0" "https://nodejs.org/dist/v12.0.0/node-v12.0.0.tar.gz#<SHA2>"
```

node-build will attempt to construct a mirror url by invoking `NODE_BUILD_MIRROR_CMD` with two arguments: `package_url` and `checksum`.
The provided command should print the desired mirror's complete package URL.
If `NODE_BUILD_MIRROR_CMD` is unset, package mirror URL construction defaults to replacing `https://nodejs.org/dist` with `NODE_BUILD_MIRROR_URL`.

node-build will first try to fetch this package from `$NODE_BUILD_MIRROR_URL/<SHA2>`
(note: this is the complete URL), where `<SHA2>` is the checksum for the file.

It will fall back to downloading the package from the original location if:
- the package was not found on the mirror;
- the mirror is down;
- the download is corrupt, i.e. the file's checksum doesn't match;
- no tool is available to calculate the checksum; or
- `NODE_BUILD_SKIP_MIRROR` is enabled.

You may specify a custom mirror by setting `NODE_BUILD_MIRROR_URL`.

#### Keeping the build directory after installation

Both `node-build` and `nodenv install` accept the `-k` or `--keep` flag, which
tells node-build to keep the downloaded source after installation. This can be
useful if you need to use `gdb` and `memprof` with Node.

Source code will be kept in a parallel directory tree `$(nodenv root)/sources`
when using `--keep` with the `nodenv install` command. You should specify the
location of the source code with the `NODE_BUILD_BUILD_PATH` environment
variable when using `--keep` with `node-build`.

#### Retry installation without v/node-/node-v prefix

The nodenv-install plugin can attempt a retry if the installation failed due
to a missing definition file. If the given node version name begins with
'v', 'node', or 'node-v', the retry will drop the prefix and try again. For
instance, if `nodenv install node-v11.0.0` fails because a definition file
does not exist by the name "node-v11.0.0", it will retry as "11.0.0".
For this retry to be attempted, the environment variable `NODENV_PREFIX_RETRY`
must be non-empty.

## Getting Help

Please see the [node-build wiki][wiki] for solutions to common problems.
Also, check out the [ruby-build wiki][].

If you can't find an answer on the wiki, open an issue on the [issue tracker][].
Be sure to include the full build log for build failures.

## Credits

Forked from [Sam Stephenson][]'s [ruby-build][] by [Will McKenzie][]
and modified for node.

[nodenv]: https://github.com/nodenv/nodenv
[ruby-build]: https://github.com/rbenv/ruby-build
[definitions]: https://github.com/nodenv/node-build/tree/master/share/node-build
[wiki]: https://github.com/nodenv/node-build/wiki
[ruby-build wiki]: https://github.com/rbenv/ruby-build/wiki
[build-env]: https://github.com/nodenv/node-build/wiki#suggested-build-environment
[issue tracker]: https://github.com/nodenv/node-build/issues
[node-build-update-defs]: https://github.com/nodenv/node-build-update-defs
[Sam Stephenson]: https://github.com/sstephenson
[Will McKenzie]: https://github.com/oinutter
