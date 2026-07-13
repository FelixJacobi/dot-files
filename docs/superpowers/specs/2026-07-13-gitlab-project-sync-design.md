# GitLab project workspace synchronizer design

## Goal
Keep `~/git/iserv` synchronized with every GitLab project below `git.iserv.eu/iserv`, using each project's namespace as its local directory path.

## Layout
For a GitLab project whose `path_with_namespace` is `iserv/lib/foo`, the checkout is `~/git/iserv/lib/foo`. A top-level project such as `iserv/foo` is `~/git/iserv/foo`.

## Configuration
`--host` selects the GitLab hostname and `--namespace` selects the recursively enumerated GitLab group; both default to `git.iserv.eu` and `iserv`. `--workspace` selects the local checkout root and defaults to `~/git/iserv`. `--quiet` suppresses routine `fetch:` notices but retains moves, clones, and conflicts.

## Safety model
The synchronizer must never delete files, reset a checkout, clean untracked files, overwrite a destination, or move an unknown directory. It discovers existing repositories by the canonical origin URL, including legacy `git:<namespace>/<project>.git` origins. When an occupied expected target's old origin resolves through GitLab to the same numeric project ID, it repairs the origin to GitLab's current SSH URL; otherwise it reports a conflict and skips it. It moves a known checkout to its namespace path only if that target path is absent.
Generated `.gitlab-ci-local` clone/cache trees are excluded from repository discovery.

## Synchronization
The script lists group projects recursively through `glab api`. In `--dry-run` mode (the default), it reports each action. With `--apply`, it moves known legacy checkouts, fetches each existing matching checkout with `git fetch --prune`, and clones missing projects using their SSH URL. A nonzero exit status indicates conflicts or failed operations.

## Installation
The development-only `docs/` tree is excluded from `install.sh` so neither the design nor implementation plan is installed into the home directory.
