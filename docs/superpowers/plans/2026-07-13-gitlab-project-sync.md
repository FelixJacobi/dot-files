# GitLab Project Workspace Synchronizer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an idempotent, lossless synchronizer for all projects in the GitLab `iserv` namespace.

**Architecture:** A POSIX shell script queries the GitLab group API through `glab`, derives each checkout path from `path_with_namespace`, and builds an inventory of existing local Git repositories by canonical origin URL. It reports all changes by default and only moves, fetches, or clones when `--apply` is supplied.

**Tech Stack:** POSIX shell, `glab`, `git`, `jq`.

## Global Constraints

- Script path is `~/git/dot-files/bin/sync-gitlab-projects`.
- Workspace root defaults to `~/git/iserv`.
- Source GitLab namespace is `iserv` on `git.iserv.eu`.
- `--host` and `--namespace` override the GitLab hostname and source group.
- Default mode must be non-mutating `--dry-run`.
- Never delete, reset, clean, overwrite, or automatically reconcile conflicts.
- Exclude `docs/` from `install.sh` deployment.

---

### Task 1: Implement safe project discovery and planning

**Files:**
- Create: `bin/sync-gitlab-projects`
- Test: manual fixture workspace with bare Git repositories and mocked `glab`/`git` commands

**Interfaces:**
- Consumes: `glab api --paginate 'groups/iserv/projects?include_subgroups=true&per_page=100&simple=true'`
- Produces: one planned action per project: `move`, `fetch`, `clone`, or `conflict`

- [ ] **Step 1: Implement option parsing and dependency checks**

```sh
case "${1:-}" in
  ''|--dry-run) apply=false ;;
  --apply) apply=true ;;
  *) printf '%s\n' "Usage: $0 [--dry-run|--apply]" >&2; exit 2 ;;
esac
command -v glab >/dev/null && command -v git >/dev/null && command -v jq >/dev/null || exit 127
```

- [ ] **Step 2: List projects and derive paths**

```sh
glab api --paginate 'groups/iserv/projects?include_subgroups=true&per_page=100&simple=true' |
jq -r '.[] | [.ssh_url_to_repo, .path_with_namespace] | @tsv'
```

Reject an entry unless its namespace begins with `iserv/`, then strip that prefix to form the target relative path.

- [ ] **Step 3: Inventory existing repositories by canonical origin**

```sh
find "$workspace" -type d -name .git -prune -print | while IFS= read -r dotgit; do
  repo=${dotgit%/.git}
  origin=$(git -C "$repo" remote get-url origin 2>/dev/null || :)
  printf '%s\t%s\n' "$origin" "$repo"
done
```

Normalize SSH and HTTPS GitLab origin variants to a single `git.iserv.eu/<path-without-.git>` key before matching.
Prune every `.gitlab-ci-local` subtree from this inventory because it contains generated clones, not workspace checkouts.

- [ ] **Step 4: Plan and report safe actions**

For a matching local repository at a different target path, plan `move` only if the target does not exist. If it exists, report `conflict`. For an expected target whose origin differs, report `conflict`. Otherwise plan `fetch` for a matching checkout or `clone` for no checkout.

- [ ] **Step 5: Verify dry-run behavior**

Run: `HOME="$fixture_home" bin/sync-gitlab-projects --dry-run`

Expected: action report only; fixture directory tree and all Git references remain unchanged.

### Task 2: Apply actions without data loss

**Files:**
- Modify: `bin/sync-gitlab-projects`
- Test: manual fixture workspace with one legacy checkout, one existing checkout, one missing checkout, and one path conflict

**Interfaces:**
- Consumes: Task 1 action plan and `--apply`
- Produces: moved/fetched/cloned checkouts plus conflict exit status

- [ ] **Step 1: Add guarded action executor**

```sh
if "$apply"; then
  case "$action" in
    move) mkdir -p "$(dirname "$target")" && mv -- "$source" "$target" ;;
    fetch) git -C "$target" fetch --prune ;;
    clone) mkdir -p "$(dirname "$target")" && git clone "$ssh_url" "$target" ;;
  esac
fi
```

Do not execute a `conflict` action. Set a failure flag for conflicts and command failures.

- [ ] **Step 2: Verify apply behavior in a fixture workspace**

Run: `HOME="$fixture_home" bin/sync-gitlab-projects --apply`

Expected: legacy checkout moves intact, existing checkout is fetched, missing checkout is cloned, conflict is skipped, and the command exits nonzero because of the conflict.

- [ ] **Step 3: Verify idempotency**

Run: `HOME="$fixture_home" bin/sync-gitlab-projects --dry-run`

Expected: only `fetch` actions remain for synchronized projects; no `move` or `clone` action is reported.
