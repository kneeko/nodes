function midpoint(a, b)

	local ax, ay = unpack(a)
	local bx, by = unpack(b)

	local x = ax + (bx - ax) * 0.5 
	local y = ay + (by - ay) * 0.5 

	return x, y
	
end