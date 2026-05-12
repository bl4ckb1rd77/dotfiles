local terminal = "kitty"
local fileManager = "caja"
local browser = "brave"
local player = "spotify"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local ipc = "qs -c noctalia-shell ipc call"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_raw(terminal .. " --title='floatkitty'"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(ipc .. " launcher toggle"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(ipc .. " plugin:keybind-cheatsheet toggle"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(ipc .. " wallpaper toggle"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(ipc .. " lockScreen lock"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(ipc .. " plugin:clipboard toggle"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(ipc .. " sessionMenu toggle"))
hl.bind(mainMod .. " + I", hl.dsp.exec_raw(terminal .. " --title='sysinfo' -e ~/.config/hypr/scripts/sysinfo"))
hl.bind(mainMod .. " + N", hl.dsp.exec_raw(terminal .. " -e nvim"))
hl.bind("switch:[Lid Switch]", hl.dsp.exec_cmd(ipc .. " lockScreen lock"))
hl.bind("ALT + D", hl.dsp.exec_raw("vesktop"))
hl.bind("ALT + M", hl.dsp.exec_raw(player))
hl.bind("ALT + E", hl.dsp.exec_raw(fileManager))
hl.bind("ALT + B", hl.dsp.exec_raw(browser))

hl.bind(mainMod .. "+ S", hl.dsp.exec_cmd("hyprshot --freeze -m output"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot --freeze -m window"))
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("hyprshot --freeze -m region"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + ALT + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + ALT + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + F11", hl.dsp.window.fullscreen({ fullscreen, toggle }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(" + ALT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ workspace = "e+1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

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
