#!/usr/bin/env bash

# Declare selected preferences here with:
#
#   declare_macos_default \
#     "human-readable label" domain key bool|int|string|float value [process-to-restart]
#
# Existing inventory and upstream defaults scripts are evidence, not desired
# state. Every declaration below is an explicit choice.
macos_major_version() {
  if [[ -n "${DOTFILES_TEST_MACOS_MAJOR:-}" ]]; then
    printf '%s\n' "$DOTFILES_TEST_MACOS_MAJOR"
  else
    sw_vers -productVersion | awk -F. '{print $1}'
  fi
}

desired_macos_workspace_shortcuts() {
  # These are Apple's own symbolic-hotkey IDs and physical key codes from the
  # current macOS DefaultSpacesShortcuts.xml. They manage only Desktop 1-9 and
  # preserve every unrelated shortcut in AppleSymbolicHotKeys.
  local keycodes=(18 19 20 21 23 22 26 28 25)
  local index hotkey_id keycode
  for index in 1 2 3 4 5 6 7 8 9; do
    hotkey_id=$((117 + index))
    keycode="${keycodes[$((index - 1))]}"
    declare_macos_symbolic_hotkey \
      "Switch to Desktop $index with Command-$index" \
      "$hotkey_id" "$keycode" 1048576
  done
  declare_macos_workspace_count 9
}

desired_macos_defaults() {
  declare_macos_dark_mode "Dark appearance" true

  if (( $(macos_major_version) >= 26 )); then
    declare_macos_default \
      "Use the transparent macOS Tahoe menu bar" \
      com.apple.desktopsettings.menubar showOpaqueMenuBar bool false ControlCenter
    declare_macos_default \
      "Use Clear Liquid Glass" \
      NSGlobalDomain NSGlassDiffusionSetting int 0 ControlCenter
  fi
  declare_macos_default \
    "Do not tint windows with the wallpaper" \
    NSGlobalDomain AppleReduceDesktopTinting bool true
  declare_macos_default \
    "Keep the menu bar visible outside full screen" \
    NSGlobalDomain _HIHideMenuBar bool false SystemUIServer
  declare_macos_default \
    "Hide the menu bar in full screen" \
    NSGlobalDomain AppleMenuBarVisibleInFullscreen bool false SystemUIServer

  declare_macos_host_default \
    "Show Wi-Fi in the menu bar" \
    com.apple.controlcenter WiFi int 18 ControlCenter
  declare_macos_host_default \
    "Show Battery in the menu bar" \
    com.apple.controlcenter Battery int 18 ControlCenter
  declare_macos_host_default \
    "Show battery percentage" \
    com.apple.controlcenter BatteryShowPercentage bool true ControlCenter
  declare_macos_host_default \
    "Always show Focus in the menu bar" \
    com.apple.controlcenter FocusModes int 18 ControlCenter
  declare_macos_host_default \
    "Show Screen Mirroring only when active" \
    com.apple.controlcenter ScreenMirroring int 2 ControlCenter
  declare_macos_host_default \
    "Show Display only when active" \
    com.apple.controlcenter Display int 2 ControlCenter
  declare_macos_host_default \
    "Show Sound only when active" \
    com.apple.controlcenter Sound int 2 ControlCenter
  declare_macos_host_default \
    "Show Now Playing only when active" \
    com.apple.controlcenter NowPlaying int 2 ControlCenter
  declare_macos_host_default \
    "Hide Siri from the menu bar" \
    com.apple.controlcenter Siri int 8 ControlCenter
  declare_macos_host_default \
    "Hide Spotlight from the menu bar" \
    com.apple.controlcenter Spotlight int 8 ControlCenter

  declare_macos_default "Dock position" com.apple.dock orientation string right
  declare_macos_default "Automatically hide the Dock" com.apple.dock autohide bool true
  declare_macos_default "Dock tile size" com.apple.dock tilesize int 43
  declare_macos_default "Keep Spaces in a stable order" com.apple.dock mru-spaces bool false
  declare_macos_default \
    "Do not reveal the desktop when its background is clicked" \
    com.apple.WindowManager EnableStandardClickToShowDesktop bool false

  declare_macos_default "Fast key repeat" NSGlobalDomain KeyRepeat int 2
  declare_macos_default "Initial key repeat delay" NSGlobalDomain InitialKeyRepeat int 25
  declare_macos_default \
    "Jump to the clicked location in scroll bars" \
    NSGlobalDomain AppleScrollerPagingBehavior bool true

  declare_macos_default \
    "Show hidden files in Finder" \
    com.apple.finder AppleShowAllFiles bool true Finder
  declare_macos_default \
    "Show all filename extensions" \
    NSGlobalDomain AppleShowAllExtensions bool true Finder
  declare_macos_default "Show Finder path bar" com.apple.finder ShowPathbar bool true Finder
  declare_macos_default "Show Finder status bar" com.apple.finder ShowStatusBar bool true Finder
  declare_macos_default \
    "Keep folders above files in Finder" \
    com.apple.finder _FXSortFoldersFirst bool true Finder
  declare_macos_default \
    "Search the current Finder folder by default" \
    com.apple.finder FXDefaultSearchScope string SCcf Finder
  declare_macos_default \
    "Use list view in new Finder windows" \
    com.apple.finder FXPreferredViewStyle string Nlsv Finder
  declare_macos_default \
    "Allow filename extension changes without a warning" \
    com.apple.finder FXEnableExtensionChangeWarning bool false Finder
  declare_macos_default \
    "Open new Finder windows at the home directory" \
    com.apple.finder NewWindowTarget string PfHm Finder
  declare_macos_default \
    "Use the home directory as the new Finder window target" \
    com.apple.finder NewWindowTargetPath string "file://$HOME/" Finder
  declare_macos_default \
    "Hide internal disks from the desktop" \
    com.apple.finder ShowHardDrivesOnDesktop bool false Finder
  declare_macos_default \
    "Hide external disks from the desktop" \
    com.apple.finder ShowExternalHardDrivesOnDesktop bool false Finder
  declare_macos_default \
    "Hide removable media from the desktop" \
    com.apple.finder ShowRemovableMediaOnDesktop bool false Finder
  declare_macos_default \
    "Hide mounted servers from the desktop" \
    com.apple.finder ShowMountedServersOnDesktop bool false Finder
  declare_macos_default \
    "Hide all Finder desktop icons" \
    com.apple.finder CreateDesktop bool false Finder
  declare_macos_default \
    "Keep desktop icons hidden by Window Manager" \
    com.apple.WindowManager StandardHideDesktopIcons bool true Finder

  declare_macos_default \
    "Avoid .DS_Store files on network volumes" \
    com.apple.desktopservices DSDontWriteNetworkStores bool true
  declare_macos_default \
    "Avoid .DS_Store files on USB volumes" \
    com.apple.desktopservices DSDontWriteUSBStores bool true

  declare_macos_default \
    "Expand Save dialogs" \
    NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true
  declare_macos_default \
    "Expand Save dialogs in modern applications" \
    NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true
  declare_macos_default \
    "Save new documents locally by default" \
    NSGlobalDomain NSDocumentSaveNewDocumentsToCloud bool false

  declare_macos_default \
    "Use key repeat instead of press-and-hold accents" \
    NSGlobalDomain ApplePressAndHoldEnabled bool false
  declare_macos_default \
    "Disable automatic capitalization" \
    NSGlobalDomain NSAutomaticCapitalizationEnabled bool false
  declare_macos_default \
    "Disable smart dashes" \
    NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool false
  declare_macos_default \
    "Disable automatic period substitution" \
    NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool false
  declare_macos_default \
    "Disable smart quotes" \
    NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool false
  declare_macos_default \
    "Disable automatic spelling correction" \
    NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool false
  declare_macos_default \
    "Enable full keyboard navigation" \
    NSGlobalDomain AppleKeyboardUIMode int 3

  declare_macos_default \
    "Hide recent applications from the Dock" \
    com.apple.dock show-recents bool false Dock
  declare_macos_default \
    "Minimize windows into their application icon" \
    com.apple.dock minimize-to-application bool true Dock

  declare_macos_default \
    "Enable native window tiling by dragging to screen edges" \
    com.apple.WindowManager EnableTilingByEdgeDrag bool true
  declare_macos_default \
    "Enable native window tiling while holding Option" \
    com.apple.WindowManager EnableTilingOptionAccelerator bool true
  declare_macos_default \
    "Allow dragging to the menu bar to fill the screen" \
    com.apple.WindowManager EnableTopTilingByEdgeDrag bool true
  declare_macos_default \
    "Remove margins around natively tiled windows" \
    com.apple.WindowManager EnableTiledWindowMargins bool false
  declare_macos_default \
    "Do not enter Mission Control when a window reaches the top edge" \
    com.apple.dock enterMissionControlByTopWindowDrag bool false Dock

  declare_macos_default "Create plain-text TextEdit documents" com.apple.TextEdit RichText int 0 TextEdit
  declare_macos_default \
    "Read plain text as UTF-8 in TextEdit" \
    com.apple.TextEdit PlainTextEncoding int 4 TextEdit
  declare_macos_default \
    "Write plain text as UTF-8 in TextEdit" \
    com.apple.TextEdit PlainTextEncodingForWrite int 4 TextEdit

  declare_macos_default \
    "Open Activity Monitor's main window on launch" \
    com.apple.ActivityMonitor OpenMainWindow bool true
  declare_macos_default \
    "Show all processes in Activity Monitor" \
    com.apple.ActivityMonitor ShowCategory int 0
  declare_macos_default \
    "Sort Activity Monitor by CPU usage" \
    com.apple.ActivityMonitor SortColumn string CPUUsage
  declare_macos_default \
    "Sort highest CPU usage first in Activity Monitor" \
    com.apple.ActivityMonitor SortDirection int 0
  declare_macos_default \
    "Show CPU history in Activity Monitor's Dock icon" \
    com.apple.ActivityMonitor IconType int 5

  declare_macos_host_default \
    "Do not open Photos when a camera or device connects" \
    com.apple.ImageCapture disableHotPlug bool true

  desired_macos_workspace_shortcuts

  declare_macos_visible_directory "Show the user Library folder in Finder" "$HOME/Library"

  local screenshot_directory="$HOME/Pictures/Screenshots"
  if ensure_directory "$screenshot_directory"; then
    declare_macos_default \
      "Save screenshots in the Screenshots folder" \
      com.apple.screencapture location string "$screenshot_directory" SystemUIServer
    declare_macos_default \
      "Capture screenshots in SDR" \
      com.apple.screencapture captureHDR bool false SystemUIServer
    declare_macos_default \
      "Save screenshots as PNG" \
      com.apple.screencapture type string png SystemUIServer
    declare_macos_default \
      "Disable the floating screenshot thumbnail" \
      com.apple.screencapture show-thumbnail bool false SystemUIServer
    declare_macos_default \
      "Exclude window shadows from screenshots" \
      com.apple.screencapture disable-shadow bool true SystemUIServer
  fi

  # Omamac restarts both after applying preferences. Preserve that selected
  # behavior, but only when at least one preference actually differs.
  if [[ "${MACOS_DEFAULTS_DIRTY:-0}" == "1" ]]; then
    queue_macos_default_restart Dock
    queue_macos_default_restart ControlCenter
  fi
}
