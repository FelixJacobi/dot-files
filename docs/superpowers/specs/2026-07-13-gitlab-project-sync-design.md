# GitLab project workspace synchronizer design

## Goal
Keep `~/git/iserv` synchronized with every GitLab project below `git.iserv.eu/iserv`, using each project's namespace as its local directory path.

## Layout
For a GitLab project whose `path_with_namespace` is `iserv/lib/foo`, the checkout is `~/git/iserv/lib/foo`. A top-level project such as `iserv/foo` is `~/git/iserv/foo`.

## Safety model
The synchronizer must never delete files, reset a checkout, clean untracked files, overwrite a destination, or move an unknown directory. It discovers existing repositories by the canonical origin URL. It moves a known checkout to its namespace path only if that target path is absent. Any duplicate or occupied target is reported as a conflict and skipped.

## Synchronization
The script lists group projects recursively through `glab api`. In `--dry-run` mode (the default), it reports each action. With `--apply`, it moves known legacy checkouts, fetches each existing matching checkout with `git fetch --prune`, and clones missing projects using their SSH URL. A nonzero exit status indicates conflicts or failed operations.
