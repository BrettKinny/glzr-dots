--- Markdown previewer: runs glow directly. piper.yazi does the same job but spawns
--- `sh`, which isn't on PATH here (only Git\cmd is).

local M = {}

local function fail(job, s) ya.preview_widget(job, ui.Text.parse(s):area(job.area):wrap(ui.Wrap.YES)) end

function M:peek(job)
	local child, err = Command("glow")
		:arg({ "-s", "dark", "-w", tostring(job.area.w), tostring(job.file.path) })
		:env("CLICOLOR_FORCE", "1") -- glow drops colour when stdout isn't a tty
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return fail(job, "glow: " .. err)
	end

	local limit = job.area.h
	local i, outs, errs = 0, {}, {}
	repeat
		local next, event = child:read_line()
		if event == 1 then
			errs[#errs + 1] = next
		elseif event ~= 0 then
			break
		end

		i = i + 1
		if i > job.skip then
			outs[#outs + 1] = next
		end
	until i >= job.skip + limit

	child:start_kill()
	if #errs > 0 then
		fail(job, table.concat(errs, ""))
	elseif job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
	else
		ya.preview_widget(job, ui.Text.parse(table.concat(outs, "")):area(job.area))
	end
end

function M:seek(job) require("code"):seek(job) end

return M
