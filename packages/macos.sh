#!/usr/bin/env bash

# Native macOS applications are explicit decisions, not inventory-derived.
# Direct downloads are allowed only with a stable upstream URL and a pinned
# digest or expected Apple signing team. Existing applications satisfy these
# declarations regardless of how they were originally installed.
desired_macos_applications() {
  [[ "${OS:-}" == "macos" ]] || return 0

  declare_direct_macos_app \
    "Alacritty" \
    "/Applications/Alacritty.app" \
    "https://github.com/alacritty/alacritty/releases/download/v0.17.0/Alacritty-v0.17.0.dmg" \
    "dmg" \
    "Alacritty.app" \
    "org.alacritty" \
    "" \
    "ad8d7de35fb38e43184776cac6dfee05ca325caa0b6639a06a55e54e4b026620"

  if [[ "$(macos_architecture)" == "arm64" ]]; then
    declare_direct_macos_app \
      "ChatGPT" \
      "/Applications/ChatGPT.app" \
      "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg" \
      "dmg" \
      "ChatGPT.app" \
      "com.openai.codex" \
      "2DC432GLL2" \
      ""
  else
    # OpenAI's current direct link is Apple-silicon-only. Homebrew's cask
    # selects OpenAI's x64 artifact on supported Intel Macs.
    declare_macos_cask "ChatGPT" "chatgpt" "/Applications/ChatGPT.app"
  fi

  declare_macos_cask "Docker Desktop" "docker-desktop" "/Applications/Docker.app"
  declare_macos_cask "Raycast" "raycast" "/Applications/Raycast.app"
  declare_macos_cask "Codex CLI" "codex" "" "codex"
  declare_macos_cask "Discord" "discord" "/Applications/Discord.app"
  declare_macos_cask "Google Chrome" "google-chrome" "/Applications/Google Chrome.app"
  declare_macos_cask "Dropbox" "dropbox" "/Applications/Dropbox.app"
  declare_macos_cask "Tailscale" "tailscale-app" "/Applications/Tailscale.app" "tailscale"
  declare_macos_cask "Insta360 Link Controller" "insta360-link-controller" "/Applications/Insta360 Link Controller.app"
  declare_macos_cask "Claude Code" "claude-code" "" "claude"

  report_manual "Open Tailscale, approve its network extension/VPN configuration, and authenticate"
  report_manual "Open Insta360 Link Controller and approve its camera extension if virtual-camera features are needed"
  report_manual "Launch Docker Desktop once and approve any requested privileged helper installation"
  report_manual "Open Dropbox, sign in, and approve its requested File Provider and Finder integration"
  report_manual "Sign in to ChatGPT/Codex and Claude Code when first used"
  report_manual "If macOS blocks Alacritty on first launch, review and approve the pinned upstream build in Privacy & Security"
}
