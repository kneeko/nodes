-- takes vertices and smooths them at joints
-- http://stackoverflow.com/questions/24771828/algorithm-for-creating-rounded-corners-in-a-polygon
smooth = function(vertices, r)

	local r = r or 20
	local m = math
	local cos = m.cos
	local sin = m.sin
	local atan2 = m.atan2
	local pi = m.pi
	local abs = m.abs
	local tau = pi * 2

	local circle = {}
	local point = {}
	local smoothed = {}

	for i = 1, #vertices, 2 do

		-- current vertex
		local x = vertices[i]
		local y = vertices[i + 1]

		-- prevous vertex
		local px = vertices[i - 2]
		local py = vertices[i - 1]

		-- next vertex
		local nx = vertices[i + 2]
		local ny = vertices[i + 3]

		-- if we have what we need...
		if (x and y) and (px and py) and (nx and ny) then

			-- the points must also not be in a line
			-- the distance between the points must also be greater than r

			-- find the point that is tangental to the joint
			-- then place a circle on that line such that it intersects x and y
			-- and has a radius of r
			-- then find the points on that circle that intersect with the prev and next line segments
			-- and evaluate the arc for sample points to populate this part

			local pa = atan2(py - y, px - x) % tau
			local na = atan2(ny - y, nx - x) % tau

			local diff = pa - na

			-- this is mighty confusing
			-- what am i doing here?
			-- this might be the source of my problems...
			local flip = (diff < 0 and diff > -pi) or (diff > pi and diff < pi*2)
			local sign = flip and -1 or 1

			local pt = (pa + (pi/2) * (sign * -1)) % tau
			local nt = (na + (pi/2) * (sign *  1)) % tau

			-- offset coords
			local plx1 = px + r * cos(pt)
			local ply1 = py + r * sin(pt)
			local plx2 = x + r * cos(pt)
			local ply2 = y + r * sin(pt)

			local nlx1 = nx + r * cos(nt)
			local nly1 = ny + r * sin(nt)
			local nlx2 = x + r * cos(nt)
			local nly2 = y + r * sin(nt)

			local ox, oy = find_intersect(plx1, ply1, plx2, ply2, nlx1, nly1, nlx2, nly2)

			local lx = ox + r * cos(pt + pi)
			local ly = oy + r * sin(pt + pi)

			local ux = ox + r * cos(nt + pi)
			local uy = oy + r * sin(nt + pi)

			circle[1] = ox
			circle[2] = oy
			circle[3] = r

			table.insert(smoothed, lx)
			table.insert(smoothed, ly)

			local samples = 7
			local interval = 1 / (samples + 1)

			-- lol ok solve this later pls
			local diff = (pt - nt)
			local arc = (diff < 0 or diff > pi) and (tau - diff % tau) or (nt - pt % tau)
			arc = (diff < -pi) and (nt - pt - tau) or (arc)

			for i = interval, interval * samples, interval do

				local delta = arc * i
				local angle = (pt + delta - pi) % tau
				local ix = ox + r * cos(angle)
				local iy = oy + r * sin(angle)
				
				table.insert(smoothed, ix)
				table.insert(smoothed, iy)

			end

			table.insert(smoothed, ux)
			table.insert(smoothed, uy)

		else

			smoothed[#smoothed + 1] = x
			smoothed[#smoothed + 1] = y

		end




	end

	return smoothed, circle, point

end
