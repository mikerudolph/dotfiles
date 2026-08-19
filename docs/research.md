# Upstream research notes

Reviewed on 2026-08-16 before implementation:

- [tobi/dotfiles](https://github.com/tobi/dotfiles): preserved its thin entry
  point, one reconciler, portable declarations, cheap shell, mise direction, and
  composable Git/shell ideas. This implementation tightens whole-file ownership:
  `ln -sf` is never used against an unmanaged destination, and apply does not pull
  or broadly upgrade packages.
- [omacom-io/omadots](https://github.com/omacom-io/omadots): used its clean split
  between shell and application config as organizational inspiration. Its
  recursive config copy and destructive Neovim replacement were intentionally not
  adopted.
- [omacom-io/omamac](https://github.com/omacom-io/omamac): informed the future
  macOS/native-app boundary. Its current package list and configuration were not
  treated as desired state.
- [basecamp/omarchy](https://github.com/basecamp/omarchy), inspected at commit
  `30f7a06090dc20dd1a4a8d0c99bfb8e2370df2ec`: current installations are
  package-backed under `/usr/share/omarchy`; `omarchy-pkg-add` is the supported
  missing-package helper; user hooks live under `~/.config/omarchy/hooks`; and the
  shipped Bash configuration explicitly reserves user customization space. This
  repository never edits the upstream tree.

1Password's current official documentation specifies `brew install
1password-cli` on macOS and a manual desktop approval under Settings → Developer.
On Linux, desktop integration additionally requires system authentication and a
running PolKit agent. Omarchy itself installs `1password-cli` through its package
helper, so this system uses that supported route instead of inventing an AUR
bootstrap. References:

- [Get started with 1Password CLI](https://www.1password.dev/cli/get-started)
- [1Password desktop app integration](https://www.1password.dev/cli/app-integration)
- [1Password for Linux installation](https://support.1password.com/install-linux/)

No existing-machine inventory file was present in the supplied empty checkout.
Consequently, no inventory data was read, copied, printed, or converted into
desired state.

## 2026-08-17 inventory decisions

The subsequently supplied inventory was used only after explicit keep/drop
decisions. Workbrew's documentation establishes `/opt/workbrew/bin/brew` as the
managed wrapper and warns that calling `/opt/homebrew/bin/brew` directly bypasses
its policy layer, so backend discovery gives Workbrew absolute precedence:

- [Workbrew PATH and wrapper guidance](https://workbrew.com/docs/troubleshooting)
- [How Workbrew authenticates private artifacts](https://workbrew.com/docs/authenticate-private-formula-artifacts)

Mise's current configuration supports global tools, `node = "lts"`, idiomatic
project version files, and registry-backed Terraform. The selected configuration
uses Node LTS; latest stable Bun, pnpm, Go, Python, Ruby, and Terraform; and Rust's
stable channel. Go does not publish an LTS channel, so `latest` is the closest
accurate expression of the requested policy.

- [Mise configuration](https://mise.jdx.dev/configuration.html)
- [Mise Node support](https://mise.jdx.dev/lang/node.html)
- [Mise walkthrough, including Terraform](https://mise.jdx.dev/walkthrough.html)

Apple documents that full Xcode already contains the command-line toolchain, while
`xcode-select --install` requests the standalone package when needed. Xcode's App
Store ID and `mas` automation constraints are documented upstream; App Store sign
in and security prompts cannot be bypassed.

- [Apple Command Line Tools](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools)
- [mas CLI automation and Xcode App Store ID](https://github.com/mas-cli/mas/blob/main/README.md)
- [Apple Rosetta guidance](https://support.apple.com/en-us/102527)

The macOS application decisions are intentionally macOS-only. Omarchy retains
Foot and its upstream-installed Docker, Codex, Discord, and Claude Code
integrations. Tailscale and Dropbox are explicit Omarchy package declarations;
their service activation and account authentication remain interactive. Notion,
Linear, VS Code, Google Earth Pro, FlightWall, Spotify, Cursor, and iTerm are not
desired state; normal apply does not remove old software, so cleanup remains an
explicit future migration if wanted.

Homebrew/Workbrew casks provide the maintained runtime download metadata for
Docker Desktop, Raycast, Codex CLI, Discord, Chrome, Tailscale's standalone app,
Wispr Flow, Granola, Insta360 Link Controller, and Claude Code. On Apple silicon ChatGPT uses OpenAI's
current official DMG URL with its Apple Team ID as the trust anchor; the cask
selects OpenAI's x64 artifact on Intel. Alacritty's cask is scheduled for
disablement on 2026-09-01 because it fails Gatekeeper, so its official v0.17.0
DMG and published SHA-256 are pinned directly and any Gatekeeper approval remains
manual.

- [OpenAI Codex CLI installation](https://developers.openai.com/codex/cli)
- [OpenAI Codex app / ChatGPT desktop download](https://developers.openai.com/codex/app)
- [Alacritty releases](https://github.com/alacritty/alacritty/releases)
- [Homebrew Alacritty cask status](https://formulae.brew.sh/cask/alacritty)
- [Tailscale macOS variants](https://tailscale.com/docs/concepts/macos-variants)
- [Tailscale system-extension approval](https://tailscale.com/kb/1340/macos-sysext)
- [Insta360 Link Controller installation](https://onlinemanual.insta360.com/link2pro/en-us/tutorial/link-controller/download%2Binstallation)
- [Arch Linux Tailscale package](https://archlinux.org/packages/extra/x86_64/tailscale/)
- [Arch Linux kubectl package](https://archlinux.org/packages/extra/x86_64/kubectl/)
- [AUR Dropbox package](https://aur.archlinux.org/packages/dropbox)

## Omamac macOS defaults reference

Omamac commit `824018b6198ac82cfdc05b5d36c53e56becc11a2` was inspected as
inspiration only. Its `install/mac.sh` enables dark appearance and declares Dock
position, Dock auto-hide and size, stable Spaces ordering, non-natural scrolling,
desktop-click behavior, 24-hour time, and keyboard repeat timing. It restarts
Dock and Control Center unconditionally. Its main installer separately sets the
Hammerspoon configuration path.

Our defaults layer does not adopt those choices automatically. It reads before
writing, reports exact dry-run changes, and restarts only affected processes
after a real change.

- [Omamac macOS preferences](https://github.com/omacom-io/omamac/blob/824018b6198ac82cfdc05b5d36c53e56becc11a2/install/mac.sh)
- [Omamac installer](https://github.com/omacom-io/omamac/blob/824018b6198ac82cfdc05b5d36c53e56becc11a2/install.sh)

The subsequently selected developer baseline adds conservative Finder display
and search behavior, expanded Save panels, local-document preference, key-repeat
behavior, disabled automatic text substitutions, Dock organization, plain-text
UTF-8 TextEdit defaults, full keyboard navigation, and a visible user Library
folder. Screenshots use the selected developer-friendly policy: an ensured
`~/Pictures/Screenshots` destination, SDR/PNG output, no floating thumbnail, and
no window shadow. Settings that weaken Gatekeeper or disk-image verification
remain out of scope.

Omamac's nine-workspace setup is currently a manual post-install checklist rather
than an implementation: create nine Spaces and enable `Command-1` through
`Command-9`. Its Hammerspoon file separately maps `Command-Control` plus the arrow
keys to directional window focus. This repository adopts only the explicitly
requested Desktop bindings. It uses Apple's current symbolic-hotkey IDs 118–126,
merges those entries without replacing the surrounding dictionary, and leaves
Space creation manual. Hammerspoon documents `hs.spaces` creation/removal as
experimental, private-API and Accessibility-based behavior, which is not suitable
for normal reconciliation.

- [Omamac workspace checklist and setup](https://github.com/omacom-io/omamac/blob/824018b6198ac82cfdc05b5d36c53e56becc11a2/install.sh)
- [Omamac hotkey overview](https://github.com/omacom-io/omamac/blob/824018b6198ac82cfdc05b5d36c53e56becc11a2/README.md#hotkeys)
- [Hammerspoon Spaces limitations](https://www.hammerspoon.org/docs/hs.spaces.html)

## Omamac application configuration and Omadots review

Omamac commit `824018b6198ac82cfdc05b5d36c53e56becc11a2` supplies a plain
Alacritty TOML file, two plain Raycast Script Commands, and an encrypted full
Raycast export. The declarative files were adapted into this repository. The
full export was rejected because Raycast's current export format can contain AI
chats, clipboard history, notes, MCP servers, snippets, extensions, settings,
aliases, and hotkeys. Raycast officially supports adding a version-controlled
Script Command directory and assigning command hotkeys in its UI.

- [Omamac Alacritty configuration](https://github.com/omacom-io/omamac/blob/824018b6198ac82cfdc05b5d36c53e56becc11a2/config/alacritty/alacritty.toml)
- [Omamac Raycast Script Commands](https://github.com/omacom-io/omamac/tree/824018b6198ac82cfdc05b5d36c53e56becc11a2/config/raycast/script-commands)
- [Raycast Script Commands](https://manual.raycast.com/script-commands)
- [Raycast import and export contents](https://manual.raycast.com/import-export)
- [Alacritty configuration reference](https://alacritty.org/config-alacritty.html)

Omadots commit `556354683664f4143776296d76df75c0fa29059a` was reviewed in
detail. Its shell and Neovim features are catalogued for selective adoption in
[`docs/omadots-review.md`](omadots-review.md). None of those features are desired
state until explicitly selected.

The later explicit selection adopted the shared LazyVim starter without
Neo-tree or language extras, enabled Neovim `autoread`, and added
`sindrets/diffview.nvim`. lazy.nvim supports automatic missing-plugin installs
and a configurable lockfile; because tracked locking was not selected, the
lockfile is routed to Neovim's XDG state directory.

- [Diffview.nvim](https://github.com/sindrets/diffview.nvim)
- [lazy.nvim structured installation](https://lazy.folke.io/installation)
- [lazy.nvim lockfiles](https://lazy.folke.io/usage/lockfile)

## Tokyo Night integration

Tokyo Night Night is the explicit macOS cross-tool palette. The upstream Neovim
theme generates maintained extras for Alacritty, eza, fzf, and lazygit; this
repository vendors small reviewed adapters from commit
`cdc07ac78467a233fd62c493de29a17e0cf2b2b6` and records their provenance beside
them. Neovim consumes the plugin normally through LazyVim instead of vendoring
plugin code.

Lazygit officially supports a comma-separated `LG_CONFIG_FILE` list and merges
the files in order, which gives its theme a composable ownership boundary. K9s
supports standalone skins and the `K9S_SKIN` selector. Current Omarchy includes
Tokyo Night as a stock theme, renders application files from `colors.toml`, and
keeps generated active state below `~/.local/state/omarchy/current`. The final
architecture deliberately makes no theme selection and installs no Tokyo Night
adapters on Omarchy, leaving that entire lifecycle to Omarchy.

- [Tokyo Night extras](https://github.com/folke/tokyonight.nvim/tree/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/extras)
- [Tokyo Night Neovim usage](https://github.com/folke/tokyonight.nvim#-installation)
- [Lazygit configuration precedence](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#config-file-locations)
- [K9s skins](https://github.com/derailed/k9s#skins)
- [Omarchy theming](https://github.com/basecamp/omarchy/blob/quattro/docs/theming.md)
- [Omarchy Tokyo Night palette](https://github.com/basecamp/omarchy/blob/quattro/themes/tokyo-night/colors.toml)

Codex supports custom TextMate `.tmTheme` files in `$CODEX_HOME/themes` and
saves selection through its `/theme` picker. Claude Code 2.1.118 and later
supports standalone JSON themes in `~/.claude/themes`, also selected with
`/theme`. Both settings files contain unrelated local state, so the dotfiles
link only the standalone theme artifacts and report the one-time selection.

- [Codex CLI customization](https://developers.openai.com/codex/cli-customization)
- [Claude Code terminal themes](https://code.claude.com/docs/en/terminal-config)
