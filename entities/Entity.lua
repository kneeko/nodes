Entity = class{
	init = function(self, key, context)

		self._key = key
		self._timestamp = os.time()
		self._context = context

		self.active = true
		self.visible = true

		-- fallback attributes
		self.type = 'generic'
		self.positioning = 'absolute'
		self.position = {0, 0, 0}
		self.angle = 0
		self.size = {0, 0}
		self.scale = {0, 0}
		self.origin = {0, 0}
		self.shear = {0, 0}
		self.threshold = {1, 1}

	end,

	project = function(self, identifier, camera, viewport)

		local positioning = self.positioning
		local projections = self.projections or {}
		local position = self.position
		local x, y, z = unpack(position)
		local cx, cy, cz = unpack(camera)
		local projection = {x, y, z}

		-- changes the relationship between really far and really close objects
		--local reciprocal = math.log(1 / z) + 1
		local reciprocal = 1 / z

		if positioning == 'absolute' then
			projection[1] = x + cx - cx * reciprocal
			projection[2] = y + cy - cy * reciprocal
		elseif positioning == 'relative' then
			local ox, oy, oz = 0, 0, 0
			local parent = self.parent
			if parent then
				ox, oy, oz = unpack(parent:project(camera, viewport))
			end
			projection[1] = ox + x + cx - cx * reciprocal
			projection[2] = oy + y + cy - cy * reciprocal
		elseif positioning == 'fixed' then
			projection[1] = cx + x
			projection[2] = cy + y
		elseif positioning == 'sticky' then
			local alignment = self.alignment or {}
			local vl, vr, vt, vb = unpack(viewport)
			local h, v, ox, oy = unpack(alignment)
			h = h or 0
			v = v or 0
			ox = ox or 0
			oy = oy or 0
			local px = vl + (vr - vl) * h
			local py = vt + (vb - vt) * v
			projection[1] = cx + x + px + ox
			projection[2] = cy + x + py + oy
		end

		-- perhaps lets this decide if it is culled?

		projections[identifier] = projection
		self.projections = projections

	end,

	context = function(self, projection)

		local angle = self.angle
		local scale = self.scale
		local origin = self.origin
		local shear = self.shear
		return projection, angle, scale, origin, shear

	end,

	distance = function(self, target)
		local x, y = unpack(self.position)
		local tx, ty = unpack(target.position)
		return tx - x, ty - y
	end,

	-- make bound, (change name of this method)
	compute = function(self)

		--[[
		the bounds this creates are relative to the object's position
		and need to be translated to its position or projection to be useful
		]]--
		
		local bound = self.bound or {}
		local size = self.size
		local angle = self.angle
		local scale = self.scale
		local origin = self.origin
		local shear = self.shear

		local w, h = size[1], size[2]
		local sx, sy = scale[1], scale[2]
		local ox, oy = origin[1], origin[2]
		local kx, ky = shear[1], shear[2]

		-- use previous tables to reduce table creation
		local points = bound and bound.points or {
			{true, true},
			{true, true},
			{true, true},
			{true, true},
		}

		local polygon = bound and bound.polygon or {
			true, true,
			true, true,
			true, true,
			true, true,
		}

		local edges = bound and bound.edges or {
			true,
			true,
			true,
			true,
		}

		edges[1] = true
		edges[2] = true
		edges[3] = true
		edges[4] = true

		ox = -ox
		oy = -oy

		if (angle ~= 0) then
			-- store intermediate results
			local cos = math.cos(angle)
			local sin = math.sin(angle)
			local xcos = cos*sx
			local xsin = sin*sx
			local ycos = cos*sy
			local ysin = sin*sy
			local wox = w + ox
			local hoy = h + oy
			points[1][1] = ox*xcos - oy*ysin
			points[1][2] = ox*xsin + oy*ycos
			points[2][1] = wox*xcos - oy*ysin
			points[2][2] = wox*xsin + oy*ycos
			points[3][1] = wox*xcos - hoy*ysin
			points[3][2] = wox*xsin + hoy*ycos
			points[4][1] = ox*xcos - hoy*ysin
			points[4][2] = ox*xsin + hoy*ycos
		else
			points[1][1] = ox*sx
			points[1][2] = oy*sy
			points[2][1] = (w + ox)*sx
			points[2][2] = oy*sy
			points[3][1] = (w + ox)*sx
			points[3][2] = (h + oy)*sy
			points[4][1] = ox*sx
			points[4][2] = (h + oy)*sy
		end

		local max = math.max
		local min = math.min
		for i = 1, #points do
			local x, y = points[i][1], points[i][2]
			polygon[i*2 - 1] = x
			polygon[i*2 + 0] = y
			edges[1] = type(edges[1]) ~= 'boolean' and min(edges[1], x) or x
			edges[2] = type(edges[2]) ~= 'boolean' and max(edges[2], x) or x
			edges[3] = type(edges[3]) ~= 'boolean' and min(edges[3], y) or y
			edges[4] = type(edges[4]) ~= 'boolean' and max(edges[4], y) or y
		end

		local circle = bound and bound.circle or {true, true, true}

		circle[1] = points[1][1] + (points[3][1] - points[1][1])*0.5
		circle[2] = points[1][2] + (points[3][2] - points[1][2])*0.5
		circle[3] = max(w*sx, h*sy)*0.5

		bound.circle = circle
		bound.edges = edges
		bound.points = points
		bound.polygon = polygon

		self.bound = bound

	end,

	debug = function(self, projection, bound)
		local bound = self.bound
		if bound then
			local edges = bound.edges
			local polygon = bound.polygon
			local circle = bound.circle
			local x, y, z = unpack(projection)
			local w, h = edges[2] - edges[1], edges[4] - edges[3]

			-- translate the points to the projection
			-- this is a hilariously way of doing this
			local points = map(function(i,v) return v + projection[((i % 2) + 1) % 2 + 1] end, polygon)

			lg.setColor(255, 0, 255)
			-- draw the collision modes
			lg.setColor(255, 255, 255)
			--lg.rectangle('line', x + edges[1], y + edges[3], w, h)
			--lg.polygon('line', unpack(points))
			--lg.circle('line', x + circle[1], y + circle[2], circle[3])

			if self.type then
				lg.print(tostring(self.type), x + 10, y - 7)
			end

			-- draw origin
			lg.circle('line', x, y, 6)
		end
	end,

	join = function(self, parent)
		self.parent = parent
	end,

	destroy = function(self)
		manager:release(self.key)
	end,
}

