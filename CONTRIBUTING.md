## Git configuration for fetching rbenv upstream

In order to continually pull changes from rbenv/ruby-build into node-build, it is necessary to add rbenv/ruby-build as a git remote.
However, this adds some complication because (by default), git tags for node-build and ruby-build will collide.
(ie, ruby-build's `v20200224` tag is not relevant for node-build yet it—and all other ruby-build tags—would be pulled by default)
Additionally, having ruby-build's tags exist locally introduces complications to the release process: `git push --follow-tags` would push ruby-build's tags to node-build's `origin` remote.

The following special git configuration avoids these and other headaches while still allowing `origin` to be pushed using `--tags` or `--follow-tags` options—without the risk of pushing ruby-build's tags into node-build's tagspace.
The configuration assumes node-build's remote is `origin`, and ruby-build's remote is `ruby-build`.

1. Configure ruby-build to not fetch tags by default:

        git config remote.ruby-build.tagOpt --no-tags

   **Beware:** the `--tags` option to `fetch` et. al. will override this setting.

2. Fetch ruby-build's tags to their own refspec namespace (`rbenv-tags`, in this case):

        git config --add remote.ruby-build.fetch '+refs/tags/*:refs/rbenv-tags/*'


Resulting snippet in `.git/config`:

```gitconfig
[remote "origin"]
	url = git@github.com:nodenv/node-build.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[remote "ruby-build"]
	url = git@github.com:rbenv/ruby-build.git
	fetch = +refs/heads/*:refs/remotes/ruby-build/*
	fetch = +refs/tags/*:refs/rbenv-tags/*
	tagopt = --no-tags
```

To reference ruby-build's tags, use the fully qualified refspec: `refs/rbenv-tags/vYYYYMMDD`

    git show refs/rbenv-tags/v20200224
    git checkout refs/rbenv-tags/v20200224
    git merge refs/rbenv-tags/v20200224

