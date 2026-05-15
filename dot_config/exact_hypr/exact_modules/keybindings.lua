local terminal = "kitty"
local fileManager = "caja"
local browser = "brave"
local player = "spotify"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local ipc = "qs -c noctalia-shell ipc call"
-- 1 Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))                                                      -- Terminal
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_raw(terminal .. " --title='floatkitty'"))                   -- Floating Terminal
hl.bind(mainMod .. " + Q", hl.dsp.window.close())                                                               -- Close Active Window
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))                                          -- Toggle Floating Window
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(ipc .. " launcher toggle"))                                          -- Startmenü
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))                                                        -- Splitt Wechseln
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(ipc .. " plugin:keybind-cheatsheet toggle"))                         -- Diese Hilfe
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(ipc .. " wallpaper toggle"))                                         -- Wallpaper Menü
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(ipc .. " lockScreen lock"))                                          -- Lock Screen
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(ipc .. " plugin:clipboard toggle"))                                  -- Clipboard Menü
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(ipc .. " sessionMenu toggle"))                                       -- Power Menü
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(ipc .. " plugin:assistant-panel toggle"))                            -- Google Gemini
hl.bind(mainMod .. " + I", hl.dsp.exec_raw(terminal .. " --title='sysinfo' -e ~/.config/hypr/scripts/sysinfo")) -- System Info
hl.bind(mainMod .. " + N", hl.dsp.exec_raw(terminal .. " -e nvim"))                                             -- NeoVim
hl.bind("switch:[Lid Switch]", hl.dsp.exec_cmd(ipc .. " lockScreen lock"))
hl.bind("ALT + D", hl.dsp.exec_raw("vesktop"))                                                                  -- Discord
hl.bind("ALT + M", hl.dsp.exec_raw(player))                                                                     -- Music Player
hl.bind("ALT + E", hl.dsp.exec_raw(fileManager))                                                                -- Dateimanager
hl.bind("ALT + B", hl.dsp.exec_raw(browser))                                                                    -- Brave
-- 2 Screenshots
hl.bind(mainMod .. "+ S", hl.dsp.exec_cmd("hyprshot --freeze -m output"))                                       -- Ganzer Bildschirm
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot --freeze -m window"))                              -- Aktuelles Fenster
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("hyprshot --freeze -m region"))                               -- Ausgewähler Bereich
-- 3 Fenster
hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ direction = "left" }))                                       -- Bewege Fenster nach Links
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ direction = "right" }))                                     -- Bewege Fenster nach rechts
hl.bind(mainMod .. " + ALT + up", hl.dsp.focus({ direction = "up" }))                                           -- Bewege Fenster nach oben
hl.bind(mainMod .. " + ALT + down", hl.dsp.focus({ direction = "down" }))                                       -- Bewege Fenster nach unten

hl.bind(mainMod .. " + F11", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
-- 4 Workspace
for i = 1, 10 do
	local key = i % 10                                                -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i })) -- Workspace Fokusieren
	hl.bind(" + ALT + " .. key, hl.dsp.window.move({ workspace = i })) -- Aktives Fenster auf Workspace verschieben
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" })) -- Workspace Scroll with Mouse
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))   -- Workspace Scroll with Mouse
hl.bind(mainMod .. " + left", hl.dsp.focus({ workspace = "e-1" }))       -- Workspace Scroll Left
hl.bind(mainMod .. " + right", hl.dsp.focus({ workspace = "e+1" }))      -- Workspace Scroll Right

-- Move/resize windows with mainMod + LMB/RMB and dragging
-- 5 Fenster Verändern
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })   -- Fenster Bewege
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- Größe ändern

-- Laptop multimedia keys for volume and LCD brightness

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind(
	"XF86TouchpadToggle",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/touchpad"),
	{ locked = true, repeating = true }
)
