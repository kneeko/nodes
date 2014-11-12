-- what is c?

function intersects(m1, c1, m2, c2)
	if m1 == m2 then
		if c1 == c2 then
			return {m1,c1,"line"}
		end
		return nil
	end
	x = (c2 - c1) / (m1 - m2)
	y = m1 * x + c1
	return {x,y,"point"}
end

function ray_intersection(a, b)
	-- the delta is the slop
	-- origin is the position
end