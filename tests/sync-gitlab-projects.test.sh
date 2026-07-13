#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT

workspace="$fixture/workspace"
mock_bin="$fixture/bin"
glab_arguments="$fixture/glab-arguments"
mkdir -p "$workspace" "$mock_bin"

git init -q "$workspace/foo"
git -C "$workspace/foo" remote add origin git:team/lib/foo.git
printf 'uncommitted work\n' > "$workspace/foo/keep-me"
git init -q "$workspace/.gitlab-ci-local/cache"
git -C "$workspace/.gitlab-ci-local/cache" remote add origin git:team/lib/foo.git

cat > "$mock_bin/glab" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$GLAB_ARGUMENTS"
printf '%s\n' '[{"path_with_namespace":"team/lib/foo","ssh_url_to_repo":"git@git.example.test:team/lib/foo.git"}]'
EOF
chmod +x "$mock_bin/glab"

cat > "$mock_bin/git" <<'EOF'
#!/usr/bin/env bash
for argument in "$@"; do
    [ "$argument" = fetch ] && exit 0
done
exec /usr/bin/git "$@"
EOF
chmod +x "$mock_bin/git"

output=$(GLAB_ARGUMENTS="$glab_arguments" PATH="$mock_bin:$PATH" "$repo_root/bin/sync-gitlab-projects" --apply --host git.example.test --namespace team --workspace "$workspace")

test -d "$workspace/lib/foo/.git"
test ! -e "$workspace/foo"
test "$(cat "$workspace/lib/foo/keep-me")" = 'uncommitted work'
test -d "$workspace/.gitlab-ci-local/cache/.git"
grep -F 'move' <<<"$output" >/dev/null
grep -F -- '--hostname git.example.test' "$glab_arguments" >/dev/null
grep -F -- 'groups/team/projects' "$glab_arguments" >/dev/null

GLAB_ARGUMENTS="$glab_arguments" PATH="$mock_bin:$PATH" "$repo_root/bin/sync-gitlab-projects" --dry-run --host git.example.test --namespace team --workspace "$workspace" >/dev/null

quiet_output=$(GLAB_ARGUMENTS="$glab_arguments" PATH="$mock_bin:$PATH" "$repo_root/bin/sync-gitlab-projects" --dry-run --quiet --host git.example.test --namespace team --workspace "$workspace")
test -z "$quiet_output"
