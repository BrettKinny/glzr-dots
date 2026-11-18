--- Downloads: newest first, modified date shown. Everything else untouched.

local function in_downloads() return cx.active.current.cwd:ends_with("Downloads") end

local function setup()
	-- The override is written into the tab's prefs, so remember what it replaced and
	-- put it back on leaving. Applied once on entry: a manual sort in Downloads sticks.
	local sort = {}
	ps.sub("ind-sort", function(opt)
		local tab, pref = cx.active.id.value, cx.active.pref
		if in_downloads() then
			if not sort[tab] then
				sort[tab] = { tostring(pref.sort_by), pref.sort_reverse, pref.sort_dir_first }
				opt.by, opt.reverse, opt.dir_first = "mtime", true, false
			end
		elseif sort[tab] then
			opt.by, opt.reverse, opt.dir_first = sort[tab][1], sort[tab][2], sort[tab][3]
			sort[tab] = nil
		end
		return opt
	end)

	local linemode = {}
	ps.sub("cd", function()
		local tab, pref = cx.active.id.value, cx.active.pref
		if in_downloads() then
			if not linemode[tab] then
				linemode[tab] = tostring(pref.linemode)
				ya.emit("linemode", { "mtime" })
			end
		elseif linemode[tab] then
			ya.emit("linemode", { linemode[tab] })
			linemode[tab] = nil
		end
	end)
end

return { setup = setup }
