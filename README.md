# node-build

[![Tests](
https://img.shields.io/github/actions/workflow/status/nodenv/node-build/test.yml?label=tests&logo=github)](
https://github.com/nodenv/node-build/actions/workflows/test.yml)
[![Latest Homebrew Release](
https://img.shields.io/homebrew/v/node-build?logo=homebrew&logoColor=white)](
https://formulae.brew.sh/formula/node-build)
[![Latest GitHub Release](
https://img.shields.io/github/v/release/nodenv/node-build?label=github&logo=github&sort=semver)](
https://github.com/nodenv/node-build/releases/latest)
[![Latest npm Release](
https://img.shields.io/npm/v/@nodenv/node-build?logo=npm&logoColor=white)](
https://www.npmjs.com/package/@nodenv/node-build/v/latest)

node-build is a command-line tool that simplifies installation of any Node version from source or precompiled binary on Unix-like systems.

It is available as a plugin for [nodenv][] as the `nodenv install` command, or as a standalone program as the `node-build` command.

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

### Homebrew package manager
```sh
brew install node-build
```

Upgrade with:
```sh
brew upgrade node-build
```

### Clone as nodenv plugin using git
```sh
git clone https://github.com/nodenv/node-build.git "$(nodenv root)"/plugins/node-build
```

Upgrade with:
```sh
git -C "$(nodenv root)"/plugins/node-build pull
```

### Install manually as a standalone program

First, download a tarball from https://github.com/nodenv/node-build/releases/latest. Then:
```sh
tar -xzf node-build-*.tar.gz
PREFIX=/usr/local ./node-build-*/install.sh
```

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

> **Warning**
> node-build mostly does not verify that system dependencies are present before downloading and attempting to compile Node from source. Please ensure that [all requisite libraries][build-env] such as build tools and development headers are already present on your system.

Firstly, if a precompiled binary exists for your platform, node-build downloads and installs it.
Otherwise it will build node from source.
Basically, what node-build does when installing a Node version is this:
- Downloads an official tarball of Node source code;
- Extracts the archive into a temporary directory on your system;
- Executes `./configure --prefix=/path/to/destination` in the source code;
- Runs `make install` to compile Node;
- Verifies that the installed Node is functional.

### Advanced Usage

#### Binaries

By default, node-build will attempt to match one of the precompiled binaries
to your platform. If there is a binary for your platform, it will install it
instead of compiling from source. To force compilation, pass the `-c` or
`--compile` flag.

#### Custom Build Definitions

To install a version of Node that is not recognized by node-build, you can specify the path to a custom build definition file in place of a Node version number.

Check out [default build definitions][definitions] as examples on how to write definition files.

##### Generating Latest-Release Build Definitions

Additionally, check out the [node-build-update-defs][] plugin.
It generates the standard build definitions for releases available from nodejs.org.
This allows you to install node versions as soon as they are available from nodejs.org,
without waiting for node-build itself to provide them. Once installed:

``` shell
nodenv update-version-defs
```

#### Custom Build Configuration

The build process may be configured through the following environment variables:

| Variable                        | Function                                                                                           |
| ------------------------------- | -------------------------------------------------------------------------------------------------- |
| `TMPDIR`                        | Where temporary files are stored.                                                                  |
| `NODE_BUILD_BUILD_PATH`         | Where sources are downloaded and built. (Default: a timestamped subdirectory of `TMPDIR`)          |
| `NODE_BUILD_CACHE_PATH`         | Where to cache downloaded package files. (Default: `~/.nodenv/cache` if invoked as nodenv plugin)  |
| `NODE_BUILD_HTTP_CLIENT`        | One of `aria2c`, `curl`, or `wget` to use for downloading. (Default: first one found in PATH)      |
| `NODE_BUILD_ARIA2_OPTS`         | Additional options to pass to `aria2c` for downloading.                                            |
| `NODE_BUILD_CURL_OPTS`          | Additional options to pass to `curl` for downloading.                                              |
| `NODE_BUILD_WGET_OPTS`          | Additional options to pass to `wget` for downloading.                                              |
| `NODE_BUILD_MIRROR_CMD`         | A command to construct the package mirror URL.                                                     |
| `NODE_BUILD_MIRROR_URL`         | Custom mirror URL root.                                                                            |
| `NODE_BUILD_MIRROR_PACKAGE_URL` | Custom complete mirror URL (e.g. http://mirror.example.com/package-1.0.0.tar.gz).                  |
| `NODE_BUILD_SKIP_MIRROR`        | Bypass the download mirror and fetch all package files from their original URLs.                   |
| `NODE_BUILD_ROOT`               | Custom build definition directory. (Default: `share/node-build`)                                   |
| `NODE_BUILD_TARBALL_OVERRIDE`   | Override the URL to fetch the node tarball from, optionally followed by `#checksum`.               |
| `NODE_BUILD_DEFINITIONS`        | Additional paths to search for build definitions. (Colon-separated list)                           |
| `CC`                            | Path to the C compiler.                                                                            |
| `NODE_CFLAGS`                   | Additional `CFLAGS` options (_e.g.,_ to override `-O3`).                                           |
| `CONFIGURE_OPTS`                | Additional `./configure` options.                                                                  |
| `MAKE`                          | Custom `make` command (_e.g.,_ `gmake`).                                                           |
| `MAKE_OPTS` / `MAKEOPTS`        | Additional `make` options.                                                                         |
| `MAKE_INSTALL_OPTS`             | Additional `make install` options.                                                                 |
| `NODE_CONFIGURE_OPTS`           | Additional `./configure` options (applies only to Node source).                                    |
| `NODE_MAKE_OPTS`                | Additional `make` options (applies only to Node source).                                           |
| `NODE_MAKE_INSTALL_OPTS`        | Additional `make install` options (applies only to Node source).                                   |

#### Applying Patches

Both `nodenv install` and `node-build` commands support the `-p/--patch` flag to apply a patch to the Node source code before building. Patches are read from standard input:

```sh
# applying a single patch
$ nodenv install --patch 11.1.0 < /path/to/node.patch

# applying a patch from HTTP
$ nodenv install --patch 11.1.0 < <(curl -sSL http://git.io/node.patch)

# applying multiple patches
$ cat fix1.patch fix2.patch | nodenv install --patch 11.1.0
```

#### Checksum Verification

All Node definition files bundled with node-build include checksums for packages, meaning that all externally downloaded packages are automatically checked for integrity after fetching.

See the next section for more information on how to author checksums.

#### Package Mirrors

To speed up downloads, node-build can fetch package files from a mirror.
To benefit from this, the packages must specify their checksum:

```sh
 # example:
 install_package "node-v12.0.0" "https://nodejs.org/dist/v12.0.0/node-v12.0.0.tar.gz#<SHA2>"
```

node-build will first try to fetch this package from `$NODE_BUILD_MIRROR_URL/<SHA2>`
(note: this is the complete URL), where `<SHA2>` is the checksum for the file. It
will fall back to downloading the package from the original location if:
- the package was not found on the mirror;
- the mirror is down;
- the download is corrupt, i.e. the file's checksum doesn't match;
- no tool is available to calculate the checksum; or
- `NODE_BUILD_SKIP_MIRROR` is enabled.

You may specify a custom mirror by setting `NODE_BUILD_MIRROR_URL`.

If a mirror site doesn't conform to the above URL format, you can specify the
complete URL by setting `NODE_BUILD_MIRROR_PACKAGE_URL`. It behaves the same as
`NODE_BUILD_MIRROR_URL` except being a complete URL.

For more control over the construction of the mirror url, you can specify a command
by setting `NODE_BUILD_MIRROR_CMD`. node-build will invoke `NODE_BUILD_MIRROR_CMD`
with two arguments: `package_url` and `checksum`. The provided command should
print the desired mirror's complete package URL to `STDOUT`.

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

  [nodenv]: https://github.com/nodenv/nodenv#readme
  [definitions]: https://github.com/nodenv/node-build/tree/main/share/node-build
  [wiki]: https://github.com/nodenv/node-build/wiki
  [build-env]: https://github.com/nodenv/node-build/wiki#suggested-build-environment
  [issue tracker]: https://github.com/nodenv/node-build/issues
  [node-build-update-defs]: https://github.com/nodenv/node-build-update-defs
  [Sam Stephenson]: https://github.com/sstephenson
  [Will McKenzie]: https://github.com/oinutter
  [ruby-build]: https://github.com/rbenv/ruby-build
  [ruby-build wiki]: https://github.com/rbenv/ruby-build/wiki
