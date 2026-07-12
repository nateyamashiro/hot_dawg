--!strict
-- Shared number formatting (additions #13): every coin/price/income render routes
-- through here so large numbers read with thousands separators (100000 → 100,000).
-- Both sides require this — client panels AND server billboards/pad labels/toasts.

local Format = {}

-- Comma-separate `n`. `decimals` (default 0) keeps that many fractional digits —
-- pass 1 for the fractional incomes variant multipliers produce (e.g. "1,234.5").
function Format.comma(n: number, decimals: number?): string
	local places = decimals or 0
	local negative = n < 0
	local rounded = math.abs(n)
	if places > 0 then
		local mult = 10 ^ places
		rounded = math.floor(rounded * mult + 0.5) / mult
	else
		rounded = math.floor(rounded + 0.5)
	end
	local text = if places > 0
		then string.format("%." .. places .. "f", rounded)
		else string.format("%d", rounded)
	local whole, fraction = string.match(text, "^(%d+)(.*)$")
	local digits = whole :: string
	local out = ""
	while #digits > 3 do
		out = "," .. string.sub(digits, -3) .. out
		digits = string.sub(digits, 1, -4)
	end
	out = digits .. out .. (fraction or "")
	return if negative then "-" .. out else out
end

return Format
