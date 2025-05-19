local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

Dotfile_path = "/home/sam/dotfiles"
Scratchpad_path = "/home/sam/scratchpad"
Project_path = "/home/sam/projects"
Work_path = "/home/sam/work"
Base_path = "/home/sam"
Git_client = "lazygit"
Editor = "/home/sam/.cargo/bin/hx"
Pixi = "/home/sam/.pixi/bin/pixi"

function Find_tab_index(win, name)
	for i, tab in ipairs(win:tabs()) do
		if tab:get_title() == name then
			return i - 1
		end
	end
	return nil
end

function File_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

function Spawn_with_title(win, cwd, name, workspace_layout)
	local tab, pane, _ = win:spawn_tab({ domain = "CurrentPaneDomain", cwd = cwd })
	tab:set_title(name)
	if workspace_layout then
		local editor_pane = nil
		-- little hacky but I'll do something more inteligent later
		if File_exists(cwd .. "/pyproject.toml") then
			editor_pane = pane:split({ args = { Pixi, "run", Editor }, cwd = cwd, direction = "Left" })
		else
			editor_pane = pane:split({ args = { Editor }, cwd = cwd, direction = "Left" })
		end

		local _git_pane = pane:split({ args = { Git_client }, cwd = cwd, direction = "Top" })
		win:gui_window():perform_action(act.ActivatePaneDirection("Left"), editor_pane)
		win:gui_window():perform_action(act.SetPaneZoomState(true), editor_pane)
	end
end

function Spawn_or_activate_tab(win, pane, name, cwd, workspace_layout)
	if cwd == nil then
		return
	end

	local tab_index = Find_tab_index(win, name)
	if tab_index == nil then
		Spawn_with_title(win, cwd, name, workspace_layout)
	else
		win:gui_window():perform_action(wezterm.action.ActivateTab(tab_index), pane)
	end
end

function Sessionize_dir(win, pane, dir)
	local choices = {}
	local _success, stdout, _stderr = wezterm.run_child_process({
		"find",
		dir,
		"-mindepth",
		"1",
		"-maxdepth",
		"2",
		"-type",
		"d",
	})

	for dir_name in string.gmatch(stdout, "[^\n]+") do
		-- I'm sorry, lua has no path operations :(
		-- should be okay since we told find to only return dirs

		local name = string.gmatch(dir_name, ".*/(.*)")()
		table.insert(choices, { id = dir_name, label = name })
	end

	win:perform_action(
		act.InputSelector({
			action = wezterm.action_callback(function(_win, _pane, id, label)
				if id and label then
					Spawn_or_activate_tab(win:mux_window(), pane, label, id, true)
				end
			end),
			fuzzy = true,
			choices = choices,
		}),
		pane
	)
end

function Sessionize_projects(win, pane)
	Sessionize_dir(win, pane, Project_path)
end

function Sessionize_work(win, pane)
	Sessionize_dir(win, pane, Work_path)
end

function Activate_pane_zoomed(win, pane, direction)
	win:perform_action(act.SetPaneZoomState(false), pane)
	win:perform_action(act.ActivatePaneDirection(direction), pane)
	win:perform_action(act.SetPaneZoomState(true), pane)
end

function Activate_pane_by_index_zoomed(win, pane, index)
	win:perform_action(act.SetPaneZoomState(false), pane)
	win:perform_action(act.ActivatePaneByIndex(index), pane)
	win:perform_action(act.SetPaneZoomState(true), pane)
end

wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, _max_width)
	local title = tab.tab_title
	local index = tab.tab_index
	return " " .. index + 1 .. ": " .. title .. " "
end)

wezterm.on("gui-startup", function(cmd)
	local tab, _pane, _win = mux.spawn_window(cmd or {})
	tab:set_title("base")
end)

return {
	check_for_updates = true,
	term = "xterm-256color",
	use_ime = true,
	default_prog = { "bash" },

	----------------
	-- Appearance --
	----------------
	color_scheme = "OneDark (base16)",
	colors = {
		tab_bar = {
			active_tab = {
				bg_color = "#282c34",
				fg_color = "#a5acb8",
			},
		},
	},
	inactive_pane_hsb = {
		saturation = 0.9,
		brightness = 0.6,
	},
	initial_rows = 50,
	initial_cols = 140,
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = false,
	tab_max_width = 32,

	-- How many lines of scrollback you want to retain per tab
	scrollback_lines = 3500,
	enable_scroll_bar = true,
	-----------
	-- Fonts --
	-----------
	font = wezterm.font_with_fallback({ "FiraCode Nerd Font", "Noto Color Emoji", "Noto Serif CJK" }),
	font_size = 14.0,
	-----------
	-- Keys  --
	-----------
	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 },
	keys = {
		-- Window management
		{
			key = "\\",
			mods = "LEADER",
			action = act.SplitHorizontal,
		},
		{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
		{ key = "=", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
		{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
		{ key = "z", mods = "CTRL", action = "TogglePaneZoomState" },
		{ key = "h", mods = "CTRL", action = act.ActivatePaneDirection("Left") },
		{ key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "CTRL", action = act.ActivatePaneDirection("Right") },
		{ key = "H", mods = "CTRL", action = act({ AdjustPaneSize = { "Left", 5 } }) },
		{ key = "J", mods = "CTRL", action = act({ AdjustPaneSize = { "Down", 5 } }) },
		{ key = "K", mods = "CTRL", action = act({ AdjustPaneSize = { "Up", 5 } }) },
		{ key = "L", mods = "CTRL", action = act({ AdjustPaneSize = { "Right", 5 } }) },
		{ key = "1", mods = "CTRL", action = act({ ActivateTab = 0 }) },
		{ key = "2", mods = "CTRL", action = act({ ActivateTab = 1 }) },
		{ key = "3", mods = "CTRL", action = act({ ActivateTab = 2 }) },
		{ key = "4", mods = "CTRL", action = act({ ActivateTab = 3 }) },
		{ key = "5", mods = "CTRL", action = act({ ActivateTab = 4 }) },
		{ key = "6", mods = "CTRL", action = act({ ActivateTab = 5 }) },
		{ key = "7", mods = "CTRL", action = act({ ActivateTab = 6 }) },
		{ key = "8", mods = "CTRL", action = act({ ActivateTab = 7 }) },
		{ key = "9", mods = "CTRL", action = act({ ActivateTab = 8 }) },
		{
			key = "e", -- editor
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				Activate_pane_by_index_zoomed(win, pane, 0)
			end),
		},
		{
			key = "g", -- git
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				Activate_pane_by_index_zoomed(win, pane, 1)
			end),
		},
		{
			key = "t", -- terminal
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				Activate_pane_by_index_zoomed(win, pane, 2)
			end),
		},
		{
			key = "Tab",
			mods = "CTRL",
			action = act.ActivateTabRelative(1),
		},
		{
			key = "Tab",
			mods = "CTRL|SHIFT",
			action = act.ActivateTabRelative(-1),
		},
		{ key = "x", mods = "LEADER", action = act({ CloseCurrentTab = { confirm = true } }) },
		-- Activate Copy Mode
		{ key = "[", mods = "CTRL", action = act.ActivateCopyMode },
		-- Paste from Copy Mode
		{ key = "]", mods = "CTRL", action = act.PasteFrom("PrimarySelection") },
		{
			key = "d",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				Spawn_or_activate_tab(win:mux_window(), pane, "dotfiles", Dotfile_path, true)
			end),
		},
		{
			key = "s",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				Spawn_or_activate_tab(win:mux_window(), pane, "scratchpad", Scratchpad_path, false)
			end),
		},
		{
			key = "b",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				Spawn_or_activate_tab(win:mux_window(), pane, "base", Base_path, false)
			end),
		},
		{ key = "f", mods = "LEADER", action = wezterm.action_callback(Sessionize_projects) },
		{ key = "w", mods = "LEADER", action = wezterm.action_callback(Sessionize_work) },
	},
	--

	key_tables = {
		-- added new shortcuts to the end
		copy_mode = {
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
			{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
			{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
			{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
			-- Enter y to copy and quit the copy mode.
			{
				key = "y",
				mods = "NONE",
				action = act.Multiple({
					act.CopyTo("ClipboardAndPrimarySelection"),
					act.CopyMode("Close"),
				}),
			},
			-- Enter search mode to edit the pattern.
			-- When the search pattern is an empty string the existing pattern is preserved
			{ key = "/", mods = "NONE", action = act({ Search = { CaseSensitiveString = "" } }) },
			{ key = "?", mods = "NONE", action = act({ Search = { CaseInSensitiveString = "" } }) },
			{ key = "n", mods = "CTRL", action = act({ CopyMode = "NextMatch" }) },
			{ key = "p", mods = "CTRL", action = act({ CopyMode = "PriorMatch" }) },
		},
	},
}
