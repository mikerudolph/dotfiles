# Architecture

## Execution flow

```text
manual 1Password Desktop install + sign-in
                    ↓
             arbitrary git clone
                    ↓
                  setup
      detect + validate platform
      verify desktop app exists
      bootstrap package backend
                    ↓
                  apply
      packages → files → includes/blocks → migrations
                    ↓
              desired state or
          explicit unresolved conflicts
```

On an existing machine, `git pull --ff-only` (or `bin/update`) leads directly to
the same `apply`. There is no second installer implementation.

All entry points derive the repository root from their script location. `paths.sh`
centralizes XDG config, data, state, and cache locations without exporting new XDG
defaults into the user's environment.

## Platform model

`platform_detect` exports:

```text
OS=macos

OS=linux
DISTRO=arch
FLAVOR=omarchy
```

Darwin is macOS. Linux identity comes from `/etc/os-release`. Omarchy requires an
Arch base plus the current package-backed installation evidence: its executable
under `/usr/share/omarchy/bin`, or both the upstream directory and an `omarchy`
command on `PATH`. Generic Arch is detected accurately but rejected because it is
not a supported target. Detection inputs are injectable for tests.

## Reconciliation contract

Every declaration uses the same primitive in plan and execution modes. Dry-run
changes only the action sink; it does not call a parallel planner.

| Strategy | Ownership evidence | Existing unmanaged behavior |
| --- | --- | --- |
| Fully managed file | destination symlink resolves inside `DOTFILES_ROOT` | conflict, untouched |
| Managed source block | unique begin/end markers for that block | add only the bounded block; malformed markers conflict |
| Git composition | exact shared `include.path` entry | add only the include; invalid/non-regular config conflicts |
| Directory | real directory already exists | non-directory conflicts |
| macOS preference | typed current value from user or current-host defaults | change only that key |
| macOS workspace shortcut | exact symbolic-hotkey entry ID | replace only Desktop shortcut IDs 118–126 |

Filesystem truth is authoritative. There is no configuration or package database.
macOS preferences similarly use `defaults read` as their current-state source;
typed declarations in `platform/macos/defaults.sh` write only differing values.
They run through the canonical reconciler, so `setup` does not have a separate or
one-time preferences path.

Control Center settings that macOS stores per host use the same typed primitive
with `defaults -currentHost`. Workspace shortcuts are merged one dictionary entry
at a time rather than replacing `AppleSymbolicHotKeys`. Creating or removing
Spaces remains manual because the available automation relies on private APIs and
Accessibility-driven Mission Control interaction.

Dock application removal is intentionally different: clearing pinned apps is a
destructive ownership transition, so it lives in migration `0001`, executes once
per Mac, and does not turn the Dock list into continuously managed desired state.
Persistent custom state exists only for successful migration markers.

Package declarations separate the logical tool, command-presence test, and native
package name. macOS explicitly prefers `/opt/workbrew/bin/brew` when present,
then uses a dynamically located Homebrew executable. This ensures a managed
laptop's policy wrapper is never bypassed. Omarchy uses its supported
`omarchy-pkg-add` command. Routine apply requests missing packages
only and performs no upgrade, removal, or cleanup operation. Runtime declarations
live in the managed mise config and are installed idempotently with mise. The macOS
login block records the Homebrew executable discovered by `command -v` or the
installer and reconciles it when needed; it never assumes a processor prefix.
Zsh activates mise locally, while Omarchy retains its upstream mise activation.

macOS system requirements use narrowly scoped reconcilers: `mas get` for
Xcode, `xcode-select --install` for a missing developer toolchain,
`xcode-select --switch` for a present full Xcode, and `softwareupdate
--install-rosetta` only on Apple silicon. Authentication and license/first-launch
steps remain explicit manual actions.

## Exit behavior

- `0`: supported platform and no ownership conflicts.
- `1`: unsupported platform or operational failure.
- `2`: command-line usage error.
- `3`: reconciliation completed its safe checks but found conflicts.

Manual 1Password approvals are reported separately. They do not authorize the
dotfiles to inspect vaults or bypass desktop security controls.

## Deliberately deferred

- GUI application, font, alias, and tool selections not yet approved from the
  inventory.
- Starship appearance, terminal, Neovim/LazyVim, agent, SSH, and service
  configuration. Their selected binaries may already be declared.
- Additional macOS defaults, LaunchAgents, permissions, and security settings.
- Omarchy Hyprland, autostart, theme, and hook customizations.
- Actual secret references, 1Password shell plugins, SSH agent, and credential
  workflows.
- Package upgrades/removals, old runtime-manager cleanup, and the explicit future
  NVM-to-mise migration.
- Mutating adoption (backup/import/replace) and the first real migration.
