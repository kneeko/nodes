function inside(x, y, polygon)
	local n = #polygon
	local inside
	local p1x, p1y = polygon[1], polygon[2]
	for i = 1, n - 2, 2 do
		local p2x, p2y = polygon[i + 2], polygon[i + 3]
		local min = math.min
		local max = math.max
		if y > min(p1y, p2y) then
			if y <= max(p1y, p2y) then
				if x <= max(p1x, p2x) then
					local xinters
					if p1y ~= p2y then
						xinters = (y-p1y)*(p2x-p1x)/(p2y-p1y)+p1x
					end
					if p1x == p2x or x <= xinters then
						inside = not inside
					end
				end
			end
		end
		p1x, p1y = p2x, p2y
	end
	return inside
end