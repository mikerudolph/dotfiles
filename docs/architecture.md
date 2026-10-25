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
                    ↓
                 onboard
       detect interactive account/security work
       run only explicitly confirmed actions
```

On an existing machine, `git pull --ff-only` (or `bin/update`) leads directly to
the same `apply`. There is no second installer implementation.

On both platforms, setup runs guided onboarding after successful reconciliation
or safe file conflicts (exit 3); it preserves the conflict exit status afterward.
Fatal apply errors stop setup. Onboarding offers missing SSH/signing-key and
GitHub-token provisioning by asking for explicit 1Password field references and
invoking the standalone provisioning commands. Existing local credentials are
skipped; existing conflicting key files are left alone. A blank response skips a
step, and non-interactive runs print the manual command instead. Dry-run reports
the same pending steps without reading references, querying vaults, or writing
credentials. Desktop authentication and CLI integration approval remain manual.

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

Darwin is macOS. Linux identity comes from `/etc/os-release`; `ID=arch` and
`ID=omarchy` both normalize to the Arch base. Omarchy also requires the current
package-backed installation evidence: its executable
under `/usr/share/omarchy/bin`, or both the upstream directory and an `omarchy`
command on `PATH`. Generic Arch is detected accurately but rejected because it is
not a supported target. Other Arch derivatives remain unsupported. Detection
inputs are injectable for tests; run the regression checks with
`bash tests/platform.sh`.

## Reconciliation contract

Every declaration uses the same primitive in plan and execution modes. Dry-run
changes only the action sink; it does not call a parallel planner.

| Strategy | Ownership evidence | Existing unmanaged behavior |
| --- | --- | --- |
| Fully managed file | destination symlink resolves inside `DOTFILES_ROOT` | conflict, untouched |
| Managed source block | unique begin/end markers for that block | add only the bounded block; malformed markers conflict |
| Git composition | exact shared `include.path` entry | add only the include; invalid/non-regular config conflicts |
| Directory | real directory already exists | non-directory conflicts |
| Generated completion cache | marker inside the dotfiles-specific cache | conflict, untouched |
| macOS preference | typed current value from user or current-host defaults | change only that key |
| macOS workspace shortcut | exact symbolic-hotkey entry ID | replace only Desktop shortcut IDs 118–126 |
| macOS keyboard mapping | Caps Lock HID usage entry in `UserKeyMapping` | merge that entry; preserve every other mapping |
| Omarchy keyboard option | bounded Lua block in the user input module | preserve content outside the block and unrelated XKB options |

Filesystem truth is authoritative. There is no configuration or package database.
macOS preferences similarly use `defaults read` as their current-state source;
typed declarations in `platform/macos/defaults.sh` write only differing values.
They run through the canonical reconciler, so `setup` does not have a separate or
one-time preferences path.

Git composition is ordered common → platform → machine-local. Common behavior
and aliases live in the repository; the optional `~/.gitconfig.local` include has
final precedence. Local SSH provisioning adds a bounded block there selecting
OpenSSH's `ssh-keygen` signer and the local private-key path. Credential helpers
and unrelated local settings are preserved.

`bin/provision-ssh-key` is an explicit, one-time credential operation, separate
from ordinary reconciliation. The user selects a 1Password private-key field
reference. The CLI exports OpenSSH format directly into a mode-600 staging file
under `~/.ssh`, validates that the key is usable without a passphrase, derives
the public key, and publishes both without replacing existing files. Staging is
removed on exit. No secret values enter shell variables, reports, or the checkout.
The installed private key remains machine-local at `~/.ssh/id_dotfiles`.

Once that key exists with owner-only permissions, `apply` reconciles the exact
SSH and Git signing blocks. The SSH block is prepended because OpenSSH uses the
first scalar value; it selects the local identity and disables authentication
agents even if a later unmanaged entry selects 1Password. Other file content is
preserved. A missing key is a manual provisioning action. Doctor, ordinary apply,
and shell startup never fetch vault contents or export keys.

Control Center settings that macOS stores per host use the same typed primitive
with `defaults -currentHost`. Workspace shortcuts are merged one dictionary entry
at a time rather than replacing `AppleSymbolicHotKeys`, then macOS reloads changed
shortcut bindings through its system-provided user-settings activator. Creating
or removing Spaces remains manual because the available automation relies on
private APIs and Accessibility-driven Mission Control interaction.

Keyboard remapping is also platform-native and composable. On macOS, a managed
helper merges Caps Lock → left Control into `hidutil`'s global mapping array and a
user LaunchAgent reapplies it at login. On Omarchy, a `--`-delimited block is
added to `~/.config/hypr/input.lua`, after upstream defaults have loaded. It reads
the active `kb_options`, removes only options that consume the physical Caps Lock
key, and appends `ctrl:nocaps`; it never edits `/usr/share/omarchy`.

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
The portable shell layer activates mise for both Zsh and Bash when available;
this is local shell initialization only and performs no installation or update.

GitHub CLI runs directly and owns its machine-local authentication.
`bin/provision-github-auth` is an explicit one-time import from either the
currently selected 1Password GitHub plugin credential or an explicit token field
reference. A pipe carries the token into native `gh auth login --with-token`;
it never enters a shell variable, temporary file, command argument, or parent
environment. GitHub CLI selects its native credential store or standard local
file fallback. Provisioning rejects storage inside the checkout, symlinked
credential files, and replacement of an existing local account. It preserves
the configured Git protocol and never runs `gh auth setup-git`, so existing
Git credential helpers remain local.

The retired GitHub CLI shim is removed only when `~/.local/bin/gh` is the exact
absolute symlink older apply versions created to this checkout's `config/bin/gh`.
This check also recognizes dangling links after the tracked shim is deleted.
Unmanaged executables and other symlinks are left alone. Dry-run uses the same
removal function without unlinking. Ordinary apply and doctor check local account
metadata only, without reading a token, contacting GitHub, or querying a vault.

The macOS-only Tokyo Night layer uses the same ownership split. Complete
declarative files (Starship, eza's theme, the K9s skin, mactop and Glow themes,
and Xcode/Codex/Claude themes) are managed symlinks.
fzf, bat, and K9s select a theme through environment variables loaded only by
the macOS Zsh integration. Lazygit's theme is the final entry in its supported
comma-separated config list, preserving an explicit or default machine-local
config. On Omarchy, dotfiles neither invokes the theme selector nor installs
these adapters; Omarchy exclusively owns its active theme and generated state.
The macOS wallpaper and native accent/highlight are bounded preferences rather
than managed files. Chrome theme selection remains a checked, one-time Web Store
action so Chrome owns installation and sync while its profile stays local and
untouched. Codex and Claude theme selection is likewise interactive so their
mixed settings, authentication, plugin, and trusted-project state stays
machine-local.

macOS system requirements use narrowly scoped reconcilers: `mas get` for
Xcode, `xcode-select --install` for a missing developer toolchain,
`xcode-select --switch` for a present full Xcode, and `softwareupdate
--install-rosetta` only on Apple silicon. Authentication remains manual.
`bin/onboard` detects pending Xcode first-launch work in dry-run mode and runs
`xcodebuild -runFirstLaunch` only after explicit confirmation; this keeps
privileged, interactive work out of ordinary reconciliation.

Static macOS Zsh completions are disposable generated state under
`${XDG_CACHE_HOME:-~/.cache}/dotfiles`. Apply invokes each installed tool's
completion generator, preserves Zsh's leading `#compdef`, and adds an ownership
marker before atomically replacing only a previously generated file. An
unmarked existing file is a conflict. Shell startup merely prepends the cache to
`fpath` and uses Zsh's state-backed `compinit` dump; it performs no generation.

## Exit behavior

- `0`: supported platform and no ownership conflicts.
- `1`: unsupported platform or operational failure.
- `2`: command-line usage error.
- `3`: reconciliation completed its safe checks but found conflicts.

Manual 1Password approvals are reported separately. They do not authorize the
dotfiles to inspect vaults or bypass desktop security controls.

## Deliberately deferred

- Remaining GUI application, font, alias, and tool selections not yet approved
  from the inventory.
- Additional Neovim/LazyVim choices, SSH host rules, and service configuration.
- Additional macOS defaults, LaunchAgents, permissions, and security settings.
- Omarchy Hyprland, autostart, and hook customizations.
- Actual secret references remain machine-local; further credential workflows
  require explicit choices.
- Package upgrades/removals, old runtime-manager cleanup, and the explicit future
  NVM-to-mise migration.
- Mutating adoption (backup/import/replace) and the first real migration.
