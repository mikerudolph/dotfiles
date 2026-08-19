# Tokyo Night theme layer

Tokyo Night **Night** is the macOS palette for this repository. Tool adapters
are committed here so reconciliation never fetches theme files at shell startup
and so palette changes can be reviewed like any other configuration change.
Omarchy is intentionally excluded because its own theme selector already owns
the active palette and integrated application themes.

The Alacritty, eza, fzf, and lazygit values are adapted from
[`folke/tokyonight.nvim`](https://github.com/folke/tokyonight.nvim) at commit
`cdc07ac78467a233fd62c493de29a17e0cf2b2b6` (Apache-2.0). The K9s adapter is
adapted to the Night palette from
[`axkirillov/k9s-tokyonight`](https://github.com/axkirillov/k9s-tokyonight).
Neovim consumes the upstream plugin directly.

Adapters are intentionally independent files because each tool has a different
configuration format. `apply` links only stable, dedicated theme destinations;
the shell uses environment variables or supported multi-file composition where
a tool mixes theme and machine-local configuration.

- macOS: Omarchy's native 6016×3384 Tokyo Night winding-road wallpaper, native
  blue accent and selection highlight, and a transparent menu bar.
- Alacritty: palette embedded in the managed Alacritty file.
- Neovim/LazyVim: `folke/tokyonight.nvim`, `night` style.
- Starship: named palette in the managed prompt file.
- eza: managed `theme.yml` with an explicit `EZA_CONFIG_DIR`.
- fzf: environment-only color options sourced by the macOS shell layer.
- bat: `ansi`, so syntax colors follow the Tokyo Night terminal palette without
  a generated cache or a 1,300-line copied TextMate theme.
- lazygit: theme-only YAML appended through its supported `LG_CONFIG_FILE`
  merge list, preserving a local config when present.
- K9s: dedicated skin selected through `K9S_SKIN`, leaving the main K9s config
  and per-context configuration local.
- Xcode: standalone managed `.xccolortheme`, selected through Xcode's bounded
  `XCFontAndColorCurrentTheme` preference.
- Codex CLI: standalone managed `.tmTheme` in `$CODEX_HOME/themes`. Selection
  remains a one-time `/theme` action so the mixed `config.toml` stays local.
- Claude Code: standalone managed JSON theme in `~/.claude/themes`. Selection
  remains a one-time `/theme` action so the mixed `settings.json` stays local.
Glow and lazydocker inherit the terminal palette where they use ANSI colors,
but this repository does not own their entire configuration just to force a
theme. Raycast retains its application-managed appearance because custom
themes require Raycast Pro.
