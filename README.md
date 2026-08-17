# Dotfiles

A conservative, idempotent personal configuration system for macOS and Arch
Linux running Omarchy. The checkout may live anywhere.

## First run

Manually install, sign in to, and unlock the 1Password desktop app. Then clone
this repository and run:

```sh
./setup
```

`setup` detects the platform, establishes the native package backend when
needed, verifies that the 1Password desktop app is present, and delegates to
`bin/apply`. On macOS it prefers a managed Workbrew wrapper when present, then an
existing Homebrew, and bootstraps Homebrew only when neither exists. It never
bypasses Workbrew by calling the underlying vanilla Homebrew directly. On
Omarchy, native packages go through `omarchy-pkg-add`.

The deliberately selected native tools currently include 1Password CLI, mise,
bat, glow, GitHub CLI, ffmpeg, AWS CLI, Neovim, lazygit, lazydocker, k9s,
Starship, and zoxide. macOS additionally gets mactop and the two Zsh enhancement
plugins. Node LTS, Bun, pnpm, Go, Python, Ruby, Rust, and Terraform are declared
through mise rather than the native package manager.

On macOS, the selected application layer installs Alacritty, Docker Desktop,
Raycast, ChatGPT, Codex CLI, Discord, Google Chrome, Dropbox, Tailscale, Insta360
Link Controller, and Claude Code. These declarations do not run on Omarchy, where the
platform already supplies the corresponding Linux tools and Foot remains the
terminal. Existing application bundles or CLI commands satisfy the declarations,
so apply does not replace a direct/self-updating installation just to change its
provenance.

Before changing anything, inspect the plan and the machine:

```sh
./bin/doctor
./bin/apply --dry-run
```

For an already-managed machine:

```sh
git pull --ff-only
./bin/apply
```

Or use `./bin/update`, which refuses a dirty checkout, fast-forwards only, and
then invokes `apply`. Shell startup never performs these operations.

## Safety model

Whole-file configuration uses symlinks. A missing destination may be created; a
symlink whose resolved target is inside this checkout may be reconciled; every
other existing destination is a conflict and remains untouched.

Composable files have narrower ownership. Shell rc files receive only a bounded,
marker-delimited source block. The machine-local Git config receives only an
`include.path` entry. Existing settings, credential helpers, comments, and local
overrides remain local. Malformed managed markers, non-regular destinations, and
invalid Git configuration become conflicts rather than rewrite opportunities.

`bin/adopt` is inspection-only in this release. It reports whether a named
destination is missing, managed, or unmanaged without reading or moving its
contents.

Normal apply never removes packages, upgrades the system broadly, cleans package
manager state, adopts files, or runs a Git pull. One-time structural work belongs
in a reviewed migration and records completion under:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/migrations
```

The initial macOS migration clears every pinned application from the Dock once.
It preserves the Trash and folder/document stacks, restarts the Dock, records
completion, and never manages the application list again. This lets subsequent
manual Dock choices remain machine-local.

## 1Password boundary

The dotfiles install 1Password CLI but never store secret values and never query
vault contents during doctor. Desktop sign-in and the security approval for CLI
integration remain manual. Doctor prints the current platform-specific action:

- macOS: enable **Settings → Developer → Integrate with 1Password CLI**.
- Omarchy: first enable system authentication in **Settings → Security**, ensure
  a PolKit agent is running, then enable CLI integration in **Developer**.

Future secrets should use scoped, on-demand mechanisms such as `op run` or
`op read`; they should not be exported wholesale during shell startup.

## macOS developer prerequisites

Xcode is declared by its Mac App Store ID and obtained through `mas get` when the
signed-in App Store session permits it. Apply requests Apple's Command Line Tools
installer when no developer directory exists, selects a present full Xcode as the
active developer directory, and installs Rosetta only on Apple silicon. App Store
authentication, Apple license acceptance, and Xcode's first-launch components are
reported as manual actions when required.

## macOS defaults

Selected user preferences belong in `platform/macos/defaults.sh`. They are part
of normal `apply`—and therefore also `setup`—rather than a separate one-time
installer. The shared primitive reads each current value, compares a normalized
typed value, writes only when different, and queues affected GUI processes for a
single restart. Dry-run uses that same path and never writes a preference.

The selected baseline currently enables dark appearance; places and auto-hides a
43-point Dock on the right; keeps Spaces ordering stable; disables click-desktop
reveal; uses fast key repeat with an initial delay of 25; and applies the selected
developer-oriented Finder, text-input, save-panel, Dock, TextEdit, and keyboard
navigation preferences. On macOS 26 it selects Clear Liquid Glass and a transparent
menu bar; it also disables wallpaper tinting, hides all desktop icons, keeps a
minimal menu bar with Focus always visible, enables margin-free native tiling,
sets Activity Monitor's developer view, and prevents Photos from opening for
connected devices. The user Library directory is revealed through a separate
idempotent filesystem action. Screenshots use SDR/PNG without shadows or a
floating thumbnail and are stored in `~/Pictures/Screenshots`, which apply creates
safely when missing. Natural scrolling, tap-to-click, standard function-key mode,
always-visible scroll bars, Finder title-bar paths, and 24-hour time remain
deliberately unmanaged.

Desktop switching follows Omamac's muscle memory: Apple's symbolic-hotkey entries
118–126 are reconciled individually to `Command-1` through `Command-9`, preserving
all unrelated shortcuts. macOS only exposes destinations that actually exist, so
doctor/apply reports a manual action until nine Desktop Spaces have been created.
Space creation is not automated because the available Hammerspoon route uses
experimental private APIs and requires Accessibility control of Mission Control.
Preferences from the machine inventory or another repository are never enabled
without an explicit choice.

## macOS application sources

Native applications are declared in `packages/macos.sh`. Homebrew/Workbrew casks
provide the normal download catalog for applications they support. The two
explicit direct downloads are also kept there: on Apple silicon, ChatGPT uses
OpenAI's official latest DMG and is accepted only when its bundle ID, code
signature, and Apple Team ID match; Intel Macs use the architecture-aware cask.
Alacritty uses a pinned upstream release DMG and SHA-256 because its Homebrew
cask is scheduled to be disabled after failing Gatekeeper checks.

The direct installer downloads into an isolated temporary directory, mounts or
extracts read-only input, verifies it, and copies only a missing application into
`/Applications`. It never replaces an existing app. Mutable latest URLs require
an expected Apple signing team; unsigned or non-notarized upstream releases must
instead have a pinned digest. Security approvals are reported for the user and
are never bypassed.

## Layout

```text
setup                  thin new-machine entry point
bin/apply              canonical reconciler and dry-run
bin/update             conservative checkout update + apply
bin/doctor             read-only diagnostics
bin/adopt              inspection-only ownership transition scaffold
lib/                   paths, platform, actions, files, packages, state
config/                fully managed or included application configuration
shell/                 cheap shared and shell-specific startup fragments
migrations/            reviewed one-time transitions
docs/                   architecture and research notes
test/                   host-independent shell tests
```

See [docs/architecture.md](docs/architecture.md) for execution and ownership
details and [docs/research.md](docs/research.md) for the upstream decisions.

## Development

```sh
./test/run
```

The test runner syntax-checks every shell script and exercises platform detection,
unsupported-platform failure, managed/unmanaged files, dry-run behavior,
migrations, and repeated reconciliation in isolated temporary homes.
