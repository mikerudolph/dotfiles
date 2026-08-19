# Omadots shell and Neovim review

Reviewed from `omacom-io/omadots` commit
`556354683664f4143776296d76df75c0fa29059a` on 2026-08-18. This is a selection
catalog, not inventory-derived desired state. The selections recorded below were
adopted only after explicit approval.

## Shell

Omadots splits portable shell configuration into environment, aliases,
functions, and tool initialization, with separate Zsh options and Bash Readline
settings. That shape is compatible with this repository, but its installer is
not: it overwrites `.zshrc`, `.zprofile`, `.bashrc`, and `.bash_profile`, copies
recursively over `.config`, and force-links `.inputrc`. We would port selected
behavior into our existing managed fragments and bounded source blocks instead.

Choose any of these independently:

1. **Editor environment (recommended):** set `EDITOR=nvim` and
   `SUDO_EDITOR=nvim`. Its `.local/bin` PATH entry already exists here. Omadots
   also sets `BAT_THEME=ansi` and `MANROFFOPT=-c`; those can be separate choices.
2. **Eza listings (recommended):** `ls` becomes a long, icon-enabled,
   directories-first listing, with `lsa`, `lt`, and `lta` variants. This requires
   adding `eza` to desired packages.
3. **Directory shortcuts (recommended):** `..`, `...`, and `....`.
4. **Neovim shortcut (recommended):** `n` opens `nvim .` without arguments and
   otherwise forwards arguments to Neovim.
5. **Git shorthand:** `g`, `gcm`, `gcam`, and `gcad`. These are concise, but the
   commit aliases make it easier to skip reviewing staged changes.
6. **Fzf file helpers:** `ff` previews with Bat, `eff` opens the selection in the
   editor, and `sff` sends the selected file through `scp`. The upstream `sff`
   uses GNU `find -printf`, so a portable macOS version would need adapting. This
   requires selecting `fzf` as a package.
7. **Zoxide replaces `cd`:** a wrapper accepts real directories normally and
   falls back to zoxide search, then prints the destination. This is convenient
   but takes ownership of a fundamental shell command; the safer alternative is
   to keep zoxide's normal `z` command.
8. **Tool shorthands:** `d` for Docker, `r` for Rails, `t` for attaching/creating
   tmux, and several AI aliases. The upstream Claude and Codex aliases bypass all
   permission/sandbox prompts; those are not recommended for a default shell.
9. **Case-insensitive, eager completion (recommended):** both Zsh and Bash get
   case-insensitive matching, first-Tab menus, prefix display, colored file
   metadata, and typed-prefix history search on arrow keys.
10. **Zsh history policy (recommended):** shared append-only history across
    sessions, duplicate removal, whitespace reduction, and verification before
    executing expanded history. We should choose explicit history file and size
    limits at the same time.
11. **Zsh interaction options:** Emacs bindings, no beep, interactive comments,
    extended globbing, `AUTO_CD`, completion within words, and symlink chasing.
    These should be selected individually because `AUTO_CD`, extended globbing,
    and physical symlink traversal can subtly change command behavior.
12. **Compression helpers:** `compress PATH` creates `PATH.tar.gz`; `decompress`
    extracts a gzip tarball. Small and portable, though the name does not cover
    other archive types.
13. **SSH port-forward helpers:** start, stop, and list same-port local forwards.
    Useful if the generic same-port convention matches actual workflows; host
    names and endpoints remain machine-local.
14. **Git worktree helpers:** create a sibling worktree/branch and trust it with
    mise; remove the active worktree and branch after confirmation. The removal
    path uses forced worktree and branch deletion, so it belongs behind a stronger
    explicit safety design rather than being copied as-is.
15. **Tmux development layouts:** editor/agent/terminal pane layouts, multi-project
    windows, and tiled command swarms. These require adopting tmux and its config;
    one upstream function also targets an undefined pane variable and needs a fix.
16. **Linux removable-drive helpers:** ISO writing and whole-drive exFAT format.
    These are intentionally destructive and Linux-specific; they should remain an
    explicit utility, never ordinary shell startup behavior.
17. **`try` initialization:** initializes a scratch-project tool at `~/Work/tries`
    when present. Skip unless that tool and path are deliberately selected.
18. **Bash prompt sanitizer:** clears stale Readline display state before Starship
    renders after abnormal exits. This is small and Omarchy-specific.

Selected on 2026-08-18: 1, 2, 3, 4, 6, 7, 9, 10, 11 except forced Emacs
bindings, and 18. The portable implementation avoids GNU-only `find -printf`,
does not shadow macOS `open`, and preserves the active Zsh keymap.

Tool startup for mise, Starship, and zoxide is already implemented here. Omadots
also loads fzf from fixed `/usr/share/fzf` paths; we should use platform-aware
locations if fzf is selected. Omadots' Linux-only `open()` wrapper must not shadow
macOS `/usr/bin/open`.

## Neovim

Omadots does not contain a bespoke Neovim distribution. Its installer deletes
the existing Neovim directory, clones the official LazyVim starter, removes the
starter's Git metadata, and then overlays one file: `lazyvim.json`. That file
records install version 8 and enables only the
`lazyvim.plugins.extras.editor.neo-tree` extra.

The resulting editor is therefore:

1. **LazyVim core:** lazy.nvim bootstrap, LazyVim's standard plugin set,
   Tokyo Night fallback, update checks without notifications, and common runtime
   plugins such as gzip/tar/zip disabled for startup performance.
2. **Neo-tree extra:** Neo-tree is selected as the file explorer instead of
   LazyVim's other explorer choices.
3. **Empty customization hooks:** starter files exist for options, keymaps,
   autocmds, and plugins, but Omadots adds no custom behavior to them.
4. **Floating plugin versions:** the starter uses current Git commits rather than
   stable semantic versions. A generated `lazy-lock.json` pins the resolved graph
   after first use, but Omadots does not ship a lockfile itself.

The useful Neovim decisions are consequently small and independent:

1. Adopt a fully managed LazyVim starter as the base.
2. Choose Neo-tree as the file explorer.
3. Decide whether `lazy-lock.json` is tracked for reproducibility or kept as
   generated local state. Tracking is recommended for predictable machines, with
   upgrades made explicitly.
4. Choose language extras deliberately. The current machine's Terraform extra is
   inventory evidence only and has not been imported.
5. Decide whether Neovim should be identical across macOS and Omarchy or use a
   small platform override layer. A common config is recommended unless a real
   platform difference appears.

Any adoption will use the repository's conflict-safe managed-link primitive. It
will never repeat Omadots' `rm -rf ~/.config/nvim` behavior.

Selected on 2026-08-18: 1 and 5. The resulting shared starter also explicitly
enables `autoread` and installs `sindrets/diffview.nvim`. Neo-tree and language
extras remain unselected, and the generated lazy.nvim lockfile is kept in XDG
state because tracked locking was not selected.

References: [Omadots](https://github.com/omacom-io/omadots/tree/556354683664f4143776296d76df75c0fa29059a),
[LazyVim starter](https://github.com/LazyVim/starter),
[LazyVim installation](https://www.lazyvim.org/installation), and
[LazyVim's Neo-tree extra](https://www.lazyvim.org/extras/editor/neo-tree).
