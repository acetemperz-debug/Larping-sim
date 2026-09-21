--!strict
--[[ Format.lua -- number and currency formatting shared by server and client. ]]

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

--- Formats a raw number into a compact, social-media-looking string. 12400 -> "12.4K"
function Format.short(value: number): string
	local n = math.floor(value)
	local sign = n < 0 and "-" or ""
	n = math.abs(n)

	if n < 1000 then
		return sign .. tostring(n)
	end

	local index = 1
	local scaled = n + 0.0
	while scaled >= 1000 and index < #SUFFIXES do
		scaled /= 1000
		index += 1
	end

	if scaled >= 100 then
		return sign .. string.format("%d%s", math.floor(scaled), SUFFIXES[index])
	elseif scaled >= 10 then
		return sign .. string.format("%.1f%s", scaled, SUFFIXES[index])
	end
	return sign .. string.format("%.2f%s", scaled, SUFFIXES[index])
end

--- Adds thousands separators. 1234567 -> "1,234,567"
function Format.commas(value: number): string
	local text = tostring(math.floor(value))
	local result = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	result = result:gsub("^,", "")
	return result
end

--- Money, always in pounds, because the fake guru accent demands it.
function Format.money(value: number, compact: boolean?): string
	if compact or math.abs(value) >= 1000000 then
		return "£" .. Format.short(value)
	end
	return "£" .. Format.commas(value)
end

--- Seconds remaining -> "4:07" or "12s"
function Format.timer(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	if s < 60 then
		return s .. "s"
	end
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

function Format.percent(value: number): string
	return string.format("%d%%", math.floor(value + 0.5))
end

return Format
