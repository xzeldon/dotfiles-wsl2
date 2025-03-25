local wezterm = require 'wezterm'

-- Center window on startup
wezterm.on("gui-startup", function(cmd)
	local screen = wezterm.gui.screens().active
	local ratio = 0.8
	local width, height = screen.width * ratio, screen.height * ratio
	local _, _, window = wezterm.mux.spawn_window {
		position = {
			x = (screen.width - width) / 2,
			y = (screen.height - height) / 2,
			origin = 'ActiveScreen'
		}
	}
	window:gui_window():set_inner_size(width, height)
end)

return {
	-- General settings
	automatically_reload_config = true,
	check_for_updates = false,
	canonicalize_pasted_newlines = "LineFeed",
	mux_enable_ssh_agent = false,

	-- Appearance
	color_scheme = "Monokai (base16)",
	font = wezterm.font("JetBrainsMono Nerd Font Mono", { weight = "DemiBold" }),
	font_size = 14,
	window_background_opacity = 0.77,
	win32_system_backdrop = "Acrylic",
	window_decorations = "INTEGRATED_BUTTONS|RESIZE",

	-- Tab behavior
	hide_tab_bar_if_only_one_tab = true,
	show_tab_index_in_tab_bar = false,

	-- Window behavior
	window_close_confirmation = "NeverPrompt",

	-- Startup program
	default_domain = "WSL:Arch",

	-- Remap keys
	keys = {
		{
			key = "Q",
			mods = "CTRL",
			action = wezterm.action.CloseCurrentTab { confirm = false },
		},
	}
}
