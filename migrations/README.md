# Migrations

Place reviewed, one-time scripts here as `NNNN-description.sh`. `apply` executes
each script once and writes a completion marker under the XDG dotfiles state
directory only after success. Migrations must be idempotent internally, narrowly
scoped, secret-safe, and explain any destructive behavior in their source.

Do not use a migration when ordinary non-destructive reconciliation is enough.

`0001-clear-macos-dock-apps.sh` is an explicitly approved ownership transition.
On each Mac it clears pinned application icons once, preserves the Trash and
folder/document stacks, and then leaves subsequent Dock customization alone.
