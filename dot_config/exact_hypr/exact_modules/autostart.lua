local scriptsDir = "/home/ahoefer/.config/hypr/scripts/"
hl.on("hyprland.start", function()
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("/home/ahoefer/.config/hypr/scripts/xauthority")
	hl.exec_cmd(
		"dbus-update-actvation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland DBUS_SESSION_BUS_ADDRESS"
	)
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME")
	hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland")
	hl.exec_cmd("qs -c noctalia-shell")
	hl.exec_cmd(scriptsDir .. "touchpad -init")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
