# Dotfiles agent guidance

This is a personal, long-lived dotfiles system for macOS and Arch Linux running
Omarchy. Preserve these invariants in every change:

- `setup` assumes this repository has already been cloned. It never installs or
  authenticates the 1Password desktop application; those are manual prerequisites.
- `apply` is the single idempotent reconciler. Fresh setup and ongoing updates
  both converge through it.
- `apply` never overwrites, moves, deletes, or automatically adopts an unmanaged
  file. A whole-file destination is managed only when its symlink points inside
  this checkout. Bounded source blocks and Git includes own only their exact entry.
- Dry-run and execution use the same reconciliation functions. A dry-run must
  accurately describe `apply` and leave the target machine unchanged.
- Existing-machine inventory is evidence about conflicts and migration risk, not
  desired state. Never infer desired packages or configuration from installed
  software.
- Keep common behavior portable and isolate platform-specific behavior. Detect
  macOS and Arch/Omarchy automatically; unsupported systems fail clearly.
- `/usr/share/omarchy` is upstream-owned and read-only to this repository. Use
  Omarchy's supported user configuration, hook, and package layers.
- Secrets never enter tracked files, logs, tests, fixtures, or command output.
  Machine-local overrides and credentials remain local and untracked.
- Shell startup performs no network, Git, package installation, update, or other
  reconciliation work. Keep it cheap.
- Destructive or ownership-changing work requires explicit adoption or a reviewed,
  one-time migration. Ordinary reconciliation stays non-destructive.
- Normal `apply` installs missing declared software only. It does not uninstall
  undeclared software, clean dependencies, replace package managers, or perform
  broad package-manager upgrades.
- The dotfiles may manage 1Password CLI. 1Password desktop authentication and the
  desktop security approval for CLI integration remain manual.
- Preserve local Git credential helpers and settings by composing configuration
  with an include rather than replacing the machine-local file.

Before finishing a change, syntax-check shell scripts and run `./test/run`.

