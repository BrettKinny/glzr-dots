-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Replace Omarchy's default editor launcher with ttt (matches glzr-dots on Windows).
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "ttt editor", { tui = "ttt" })

-- Replace Omarchy's default file manager shortcut with Elio.
hl.unbind("SUPER + SHIFT + F")
-- TERM=foot: foot reports xterm-256color, which hides it from elio's Sixel
-- image-preview detection (same fix as the elio alias in ~/.bashrc).
o.bind("SUPER + SHIFT + F", "Elio file manager", "omarchy-launch-tui --app-id=org.omarchy.elio env TERM=foot elio")

-- Replace Omarchy's default ChatGPT shortcut with Gemini.
-- Zen uses Firefox's --new-window syntax; Chromium's --app= flag opens a
-- regular browser window without navigating here.
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Gemini", "uwsm-app -- /opt/zen-browser-bin/zen-bin --new-window https://gemini.google.com/app")

-- Replace Omarchy's Google Photos shortcut with Bitwarden.
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Bitwarden", "uwsm-app -- rofi-rbw")

-- Restore the terminal calendar shortcut.
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Calendar", { tui = "gcal-tui" })

-- Restore selected app shortcuts while leaving other preinstalled bindings disabled.
hl.unbind("SUPER + SHIFT + O")
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })

hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Email", "uwsm-app -- /opt/zen-browser-bin/zen-bin https://outlook.com")

hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Signal", { omarchy = "signal" })

-- Toggle TIDAL's player panel.
hl.unbind("SUPER + M")
o.bind("SUPER + M", "TIDAL", "omarchy-shell tidal overlay")

-- Hold Alt+Space to dictate into the focused application.
o.bind("ALT + SPACE", "Start voice dictation", "voxtype record start")
o.bind("ALT + SPACE", "Stop voice dictation", "voxtype record stop", { release = true })

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  -- F9 push-to-talk removed: F9 is herdr's prefix (shared with glzr-dots).
end
