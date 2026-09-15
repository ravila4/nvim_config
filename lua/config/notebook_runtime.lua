local M = {}
local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

function M.label(cell, now, indicator, frame)
	local state = cell.status
	if state == "queued" then
		return "queued"
	end
	if state ~= "running" and state ~= "done" and state ~= "error" then
		return ""
	end
	local icon = state == "done" and "✓" or "✗"
	if state == "running" then
		frame = frame or 0
		icon = frames[frame % #frames + 1]
		if indicator == "blink" then
			icon = math.floor(frame / 5) % 2 == 0 and "●" or " "
		elseif indicator == "none" then
			icon = ""
		end
	end
	local finish = state == "running" and now or cell.finished_at
	if type(cell.started_at) == "number" and type(finish) == "number" then
		return icon .. (icon ~= "" and " " or "") .. string.format("%.1fs", math.max(0, finish - cell.started_at))
	end
	return icon
end

return M
