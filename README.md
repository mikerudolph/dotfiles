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
Starship, zoxide, eza, fzf, and kubectl. macOS additionally gets mactop and the
two Zsh enhancement plugins. Omarchy additionally installs Tailscale and
Dropbox through its supported package helper. Node LTS, Bun, pnpm, Go, Python,
Ruby, Rust, and Terraform are declared through mise rather than the native
package manager.

On macOS, the selected application layer installs Alacritty, Docker Desktop,
Raycast, ChatGPT, Codex CLI, Discord, Google Chrome, Dropbox, Tailscale, Wispr
Flow, Granola, Insta360 Link Controller, Claude Code, and the JetBrains Mono Nerd
Font used by Alacritty.
These macOS application declarations do not run on Omarchy, where Foot remains
the terminal and platform packages supply the selected Linux applications.
Existing application bundles, installed casks, or CLI commands satisfy the
declarations, so apply does not replace a direct/self-updating installation just
to change its provenance.

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

## Tokyo Night

On macOS, Tokyo Night **Night** is the selected color scheme. Managed adapters
cover the desktop wallpaper, Xcode, Codex CLI, Claude Code, Alacritty,
Neovim/LazyVim, Starship, eza, fzf, lazygit, and K9s; bat uses
its ANSI theme so syntax colors follow the active terminal palette without a
generated theme cache. Lazygit's theme is appended to its supported multi-file
configuration list, while K9s uses a dedicated skin, so neither integration
replaces machine-local or per-context settings.

Omarchy is intentionally excluded from this theme layer. The dotfiles neither
select an Omarchy theme nor link theme adapters there; Omarchy's own selector
remains the sole authority for Foot and its integrated applications. Vendored
macOS adapter provenance is recorded in
[`themes/tokyonight/README.md`](themes/tokyonight/README.md).

The wallpaper is reconciled across macOS Desktop Spaces and coordinates with
the transparent menu bar. macOS uses its native blue accent plus a Tokyo Night
blue text-selection highlight. Xcode selects the managed theme automatically.
Codex and Claude Code deliberately keep their mixed local settings files: after
the theme files are linked, run `/theme` once in each CLI and select
`Tokyo Night Night`.

## Safety model

Whole-file configuration uses symlinks. A missing destination may be created; a
symlink whose resolved target is inside this checkout may be reconciled; every
other existing destination is a conflict and remains untouched.

Composable files have narrower ownership. Shell rc files receive only a bounded,
marker-delimited source block. The machine-local Git config receives only an
`include.path` entry. Existing settings, credential helpers, comments, and local
overrides remain local. Malformed managed markers, non-regular destinations, and
invalid Git configuration become conflicts rather than rewrite opportunities.

The shared Git include sets the default branch and personal identity, prunes
deleted remote branches during fetch, sorts branches by recent activity and tags
by version, pushes the current branch with automatic upstream setup, enables SSH
commit signing, and provides a small alias set. A separate macOS include selects
1Password's app-bundled signing helper. Apply includes the optional, untracked
`~/.gitconfig.local` last, allowing work identity, signing keys, credential
helpers, and machine policy to override shared defaults without editing the
repository. The selected `user.signingKey` remains local because it identifies a
specific public key in 1Password.

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

GitHub CLI authentication uses a managed executable shim at `~/.local/bin/gh`,
not a shell alias. The shim removes its own directory from `PATH` and runs the
real GitHub CLI through `op plugin run -- gh`. As a result, Claude Code, Codex,
scripts, and interactive shells all receive the same scoped 1Password credential
without storing a second token through `gh auth login` or exporting `GH_TOKEN`
to the parent shell. Run `op plugin init gh` once and choose the intended global
credential; sourcing 1Password's generated `gh` alias is unnecessary.

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

Caps Lock is remapped to left Control on both platforms. macOS uses a merged
`hidutil` `UserKeyMapping`: apply changes only the Caps Lock entry, preserves
unrelated mappings, and installs a managed user LaunchAgent to restore it at
login. Omarchy gets a bounded Lua block in its supported
`~/.config/hypr/input.lua` user layer. The block removes options that assign the
physical Caps Lock key another role (including Omarchy's Compose binding), adds
`ctrl:nocaps`, and preserves unrelated keyboard-layout options. Existing content
outside the markers remains machine-local; malformed markers are a conflict.

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

## Alacritty, Raycast, and login presentation

The macOS Alacritty configuration combines Omamac's buttonless window, generous
padding, and Option-as-Alt behavior with the current upstream Tokyo Night Night
palette. It adds dynamic padding and a bold-italic face, and deliberately lets
Alacritty choose the best installed terminfo instead of forcing
`TERM=xterm-256color`. Apply safely links it at
`${XDG_CONFIG_HOME:-~/.config}/alacritty/alacritty.toml`; an existing unmanaged
file is reported as a conflict.

Raycast receives two reviewable Script Commands for opening fresh Alacritty and
Chrome windows. Apply links them under
`${XDG_CONFIG_HOME:-~/.config}/raycast/script-commands`; Raycast still requires a
one-time **Settings → Script Commands → Add Script Directory** action and manual
hotkey assignment. Use `Command-Space` for Raycast, `Command-Control-Return` for a
new Alacritty window, and `Command-Control-Shift-Return` for a new Chrome window.

Omamac's encrypted `Raycast.rayconfig` is intentionally not tracked or imported.
Modern Raycast exports can include chats, clipboard history, notes, MCP servers,
snippets, and other private or generated state, and Omamac publishes a shared
export password. A personal Raycast backup belongs in an encrypted private backup
location, not this repository.

On macOS, `.hushlogin` is a repo-owned empty file linked into `$HOME` to suppress
the login banner. The same missing/managed/unmanaged ownership rules apply.

## Shell behavior

Shared startup config sets Neovim as `EDITOR`/`SUDO_EDITOR`, activates mise,
Starship, and zoxide without network or package activity, and provides the
selected Omadots-inspired helpers. Eza powers `ls`, `lsa`, `lt`, and `lta`;
`..`, `...`, and `....` navigate parent directories; `n` opens Neovim; and
`ff`, `eff`, and `sff` use fzf with Bat previews for file selection.

`cd` is deliberately aliased to `zd`: existing paths retain normal `cd`
semantics, while non-path arguments are resolved through zoxide. Zsh gets
case-insensitive eager completion, typed-prefix history arrows, shared
deduplicated history under `${XDG_STATE_HOME:-~/.local/state}/zsh`, extended
globbing, automatic directory changes, symlink traversal, interactive comments,
and no terminal bell. It preserves the user's current ZLE keymap instead of
forcing Emacs bindings. Omarchy Bash gets equivalent Readline completion/history
navigation behavior and prompt-display cleanup before Starship renders.

## Neovim

`config/nvim` is a common macOS/Omarchy LazyVim starter managed as one directory
symlink. It explicitly enables `autoread` and installs
[`sindrets/diffview.nvim`](https://github.com/sindrets/diffview.nvim), exposing
the standard `:DiffviewOpen`, `:DiffviewFileHistory`, and related commands. On
macOS only, the Tokyo Night plugin is loaded at high priority with the `night`
style and selected through LazyVim's supported `colorscheme` option. On Omarchy,
the plugin adapter is inert so the platform's theme selector remains authoritative.

Because reproducible lockfile management was not selected, lazy.nvim writes its
generated lockfile below Neovim's XDG state directory rather than into this
repository. Plugin binaries, caches, logs, sessions, and other runtime data also
remain outside the managed configuration. An existing unmanaged
`~/.config/nvim` is a conflict and is never moved or replaced by ordinary apply.

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
```

See [docs/architecture.md](docs/architecture.md) for execution and ownership
details and [docs/research.md](docs/research.md) for the upstream decisions.

## Development

Syntax-check changed shell scripts with `bash -n` (and `zsh -n` for Zsh
fragments). Exercise reconciliation changes through `./bin/apply --dry-run` so
the live machine remains unchanged while reviewing the plan.
