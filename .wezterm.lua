local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	default_prog = { "powershell" }
end

if wezterm.target_triple == "x86_64-unknown-linux-gnu" then
	default_prog = { "bash" }
end

dotfile_path = "/home/sam/Documents/dotfiles"
project_path = "/home/sam/Documents/projects"
work_path = "/home/sam/Documents/work"
base_path = "/home/sam"
git_client = "lazygit"
editor = "/home/sam/.cargo/bin/hx"

function find_tab_index(win, name)
	for i, tab in ipairs(win:tabs()) do
		if tab:get_title() == name then
			return i - 1
		end
	end
	return nil
end

function spawn_with_title(win, cwd, name)
	local tab, pane, _ = win:spawn_tab({ domain = "CurrentPaneDomain", cwd = cwd })
	tab:set_title(name)
	editor_pane = pane:split({ args = { editor, cwd }, cwd = cwd, direction = "Left" })
	git_pane = pane:split({ args = { git_client }, cwd = cwd, direction = "Top" })
	win:gui_window():perform_action(act.ActivatePaneDirection("Left"), editor_pane)
	win:gui_window():perform_action(act.SetPaneZoomState(true), editor_pane)
end

function spawn_or_activate_tab(win, pane, name, cwd)
	if cwd == nil then
		return
	end

	local tab_index = find_tab_index(win, name)
	if tab_index == nil then
		spawn_with_title(win, cwd, name)
	else
		win:gui_window():perform_action(wezterm.action.ActivateTab(tab_index), pane)
	end
end

function sessionize_projects(win, pane)
	local choices = {}
	local success, stdout, stderr = wezterm.run_child_process({
		"find",
		project_path,
		"-mindepth",
		"1",
		"-maxdepth",
		"2",
		"-type",
		"d",
	})

	for dir in string.gmatch(stdout, "[^\n]+") do
		-- I'm sorry, lua has no path operations :(
		-- should be okay since we told find to only return dirs

		local name = string.gmatch(dir, ".*/(.*)")()
		table.insert(choices, { id = dir, label = name })
	end

	win:perform_action(
		act.InputSelector({
			action = wezterm.action_callback(function(win, pane, id, label)
				if id and label then
					spawn_or_activate_tab(win:mux_window(), pane, label, id)
				end
			end),
			fuzzy = true,
			choices = choices,
		}),
		pane
	)
end
function sessionize_work(win, pane)
	local choices = {}
	local success, stdout, stderr = wezterm.run_child_process({
		"find",
		work_path,
		"-mindepth",
		"1",
		"-maxdepth",
		"1",
		"-type",
		"d",
	})

	for dir in string.gmatch(stdout, "[^\n]+") do
		-- I'm sorry, lua has no path operations :(
		-- should be okay since we told find to only return dirs

		local name = string.gmatch(dir, ".*/(.*)")()
		table.insert(choices, { id = dir, label = name })
	end

	win:perform_action(
		act.InputSelector({
			action = wezterm.action_callback(function(win, pane, id, label)
				if id and label then
					spawn_or_activate_tab(win:mux_window(), pane, label, id)
				end
			end),
			fuzzy = true,
			choices = choices,
		}),
		pane
	)
end

function activate_pane_zoomed(win, pane, direction)
	win:perform_action(act.SetPaneZoomState(false), pane)
	win:perform_action(act.ActivatePaneDirection(direction), pane)
	win:perform_action(act.SetPaneZoomState(true), pane)
end

function activate_pane_by_index_zoomed(win, pane, index)
	win:perform_action(act.SetPaneZoomState(false), pane)
	win:perform_action(act.ActivatePaneByIndex(index), pane)
	win:perform_action(act.SetPaneZoomState(true), pane)
end

function spawn_git_pane(win, pane)
	-- extra_pane = pane:split({ args = {"gitu"}})
	extra_pane = pane:split({ args = { "lazygit" } })
	win:perform_action(act.SetPaneZoomState(true), extra_pane)
end

wezterm.on("gui-attached", function(domain)
	-- assume only one window exists at startup.
	-- I know it's terrible but my terminal, my rules

	local window = mux.all_windows()[1]
	window:gui_window():maximize()
	tab = window:active_tab()
	tab:set_title("base")
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab.tab_title
	local index = tab.tab_index
	return " " .. index + 1 .. ": " .. title .. " "
end)

return {
	check_for_updates = true,
	term = "xterm-256color",
	use_ime = true,
	default_prog = default_prog,

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
		{ key = "-", mods = "LEADER", action = wezterm.action.DecreaseFontSize },
		{ key = "=", mods = "LEADER", action = wezterm.action.IncreaseFontSize },
		{ key = "0", mods = "LEADER", action = wezterm.action.ResetFontSize },
		{
			key = "r",
			mods = "LEADER",
			action = act.RotatePanes("CounterClockwise"),
		},
		{ key = "z", mods = "LEADER", action = "TogglePaneZoomState" },
		{
			key = "p",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_zoomed(win, pane, "Prev")
			end),
		},
		{
			key = "n",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_zoomed(win, pane, "Next")
			end),
		},
		{
			key = "g",
			mods = "CTRL",
			action = wezterm.action_callback(function(win, pane)
				spawn_git_pane(win, pane)
			end),
		},
		{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
		{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
		{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
		{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
		{ key = "H", mods = "LEADER", action = act({ AdjustPaneSize = { "Left", 5 } }) },
		{ key = "J", mods = "LEADER", action = act({ AdjustPaneSize = { "Down", 5 } }) },
		{ key = "K", mods = "LEADER", action = act({ AdjustPaneSize = { "Up", 5 } }) },
		{ key = "L", mods = "LEADER", action = act({ AdjustPaneSize = { "Right", 5 } }) },
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
			key = "1",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 0)
			end),
		},
		{
			key = "2",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 1)
			end),
		},
		{
			key = "3",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 2)
			end),
		},
		{
			key = "4",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 3)
			end),
		},
		{
			key = "5",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 4)
			end),
		},
		{
			key = "6",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 5)
			end),
		},
		{
			key = "7",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 6)
			end),
		},
		{
			key = "8",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 7)
			end),
		},
		{
			key = "9",
			mods = "ALT",
			action = wezterm.action_callback(function(win, pane)
				activate_pane_by_index_zoomed(win, pane, 8)
			end),
		},
		{ key = "x", mods = "LEADER", action = act({ CloseCurrentTab = { confirm = true } }) },
		-- Activate Copy Mode
		{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
		-- Paste from Copy Mode
		{ key = "]", mods = "LEADER", action = act.PasteFrom("PrimarySelection") },
		{
			key = "d",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				spawn_or_activate_tab(win:mux_window(), pane, "dotfiles", dotfile_path)
			end),
		},
		-- {
		-- 	key = "w",
		-- 	mods = "LEADER",
		-- 	action = wezterm.action_callback(function(win, pane)
		-- 		spawn_or_activate_tab(win:mux_window(), pane, "hydromt", work_path)
		-- 	end),
		-- },
		{
			key = "b",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				spawn_or_activate_tab(win:mux_window(), pane, "base", base_path)
			end),
		},
		{ key = "f", mods = "LEADER", action = wezterm.action_callback(sessionize_projects) },
		{ key = "w", mods = "LEADER", action = wezterm.action_callback(sessionize_work) },
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
			{ key = "m", mods = "ALT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = " ", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
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
