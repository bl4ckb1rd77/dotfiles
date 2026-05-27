local terminal = "kitty"
local fileManager = "caja"
local browser = "brave"
local player = "spotify"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local ipc = "qs -c noctalia-shell ipc call"
-- 1. Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Terminal" })
hl.bind(
	mainMod .. " + SHIFT + RETURN",
	hl.dsp.exec_raw(terminal .. " --title='floatkitty'"),
	{ description = "Floating Terminal" }
)
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close Active Window" })
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating Window" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(ipc .. " launcher toggle"), { description = "Start Menu" })
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle Split Direction (only dwindle)" })
hl.bind(
	mainMod .. " + H",
	hl.dsp.exec_cmd(ipc .. " plugin:keybind-cheatsheet toggle"),
	{ description = "Show this Help" }
)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(ipc .. " plugin:wallcards toggle"), { description = "Wallpaper Menu" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(ipc .. " lockScreen lock"), { description = "Lock Screen" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(ipc .. " plugin:clipboard toggle"), { description = "Clipboard History" })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(ipc .. " sessionMenu toggle"), { description = "Power Menu" })
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(ipc .. " plugin:assistant-panel toggle"), { description = "Google Gemini" })
hl.bind(
	mainMod .. " + I",
	hl.dsp.exec_raw(terminal .. " --title='sysinfo' -e ~/.config/hypr/scripts/sysinfo"),
	{ description = "System Info" }
)
hl.bind(mainMod .. " + N", hl.dsp.exec_raw(terminal .. " -e nvim"), { description = "NeoVim" })
hl.bind("switch:[Lid Switch]", hl.dsp.exec_cmd(ipc .. " lockScreen lock"))
hl.bind("ALT + D", hl.dsp.exec_raw("vesktop"), { description = "Discord" })
hl.bind("ALT + M", hl.dsp.exec_raw(player), { description = "Music Player" })
hl.bind("ALT + E", hl.dsp.exec_raw(fileManager), { description = "File manager" })
hl.bind("ALT + B", hl.dsp.exec_raw(browser), { description = "Browser" })
-- 2. Screenshots
hl.bind(mainMod .. "+ S", hl.dsp.exec_cmd("hyprshot --freeze -m output"), { description = "Screenshot Full Screen" })
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.exec_cmd("hyprshot --freeze -m window"),
	{ description = "Screenshot active Window" }
)
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("hyprshot --freeze -m region"), { description = "Screenshot Area" })
-- 3. Fenster
hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ direction = "left" }), { description = "Move Window Left" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ direction = "right" }), { description = "Move Window Right" })
hl.bind(mainMod .. " + ALT + up", hl.dsp.focus({ direction = "up" }), { description = "Move Window Up" })
hl.bind(mainMod .. " + ALT + down", hl.dsp.focus({ direction = "down" }), { description = "Move Window Down" })

hl.bind(
	mainMod .. " + F11",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Toggle Fullscreen" }
)

-- 4. Workspace
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Focus Workspace NUM" })
	hl.bind(
		" + ALT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move Active Window to Workspace NUM" }
	)
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(
	mainMod .. " + mouse_down",
	hl.dsp.focus({ workspace = "e+1" }),
	{ description = "Scroll Workspaces with Mouse" }
)
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll Workspaces with Mouse" })
hl.bind(mainMod .. " + left", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll Workspace Left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll Workspace Right" })

-- 5. Move Windows
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true }, { description = "Move Window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }, { description = "Resize Window" })

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
