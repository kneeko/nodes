Entity = class{
	init = function(self, context)

		self._timestamp = os.time()
		self._context = context
		self._queued = false

		self._active = true
		self._visible = true

		-- fallback attributes
		self._type = 'generic'
		self.positioning = 'absolute'
		self.position = {0, 0, 0}
		self.angle = 0
		self.size = {0, 0}
		self.scale = {0, 0}
		self.origin = {0, 0}
		self.shear = {0, 0}
		self.threshold = {1, 1}
		self.projections = {}

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

		local overrides = self.overrides
		-- objects are allowed to override their parallax scrolling speed
		-- and use their z position solely for depth ordering
		local reciprocal = overrides and 1 / overrides.parallax or 1 / z

		if positioning == 'absolute' then -- default positioning mode
			projection[1] = x + cx - cx * reciprocal
			projection[2] = y + cy - cy * reciprocal
		elseif positioning == 'relative' then
			local ox, oy, oz = 0, 0, 0

			local parents = self.parent

			if not parents then
				error('entity ' .. self._type .. ' using relative positioning without a parent')
			end

			local parent = parents._type -- all game entities will have a type defined but an array will not

			-- todo
			-- allow for a barycentric coordinate system to change
			-- how the projection is weighted between multiple parents

			-- lamba for adding the parent projection to the child projection
			local apply = function(parent, count)
				local parent_projection = parent.projections[identifier]

				-- sometimes the child of a parent will be projected
				-- before the parent has been projected so we need to cache one

				if not parent_projection then
					parent:project(identifier, camera, viewport)
					parent_projection = parent.projections[identifier]
				end

				-- average the parent projections using the count
				local px, py = unpack(parent_projection)
				ox = ox * ((count - 1) / count) + px * (1 / count)
				oy = oy * ((count - 1) / count) + py * (1 / count)
			end

			local count = 1
			local total = parents._type and 1 or #parents
			local singular = parents._type
			if singular then -- single parent
				apply(parents, count)
			else
				for _,parent in ipairs(parents) do
					apply(parent, count)
					count = count + 1
				end
			end



			--[[
			local parent = self.parent
			if parent then

				local parent_projection = parent.projections[identifier]
				-- sometimes the child of a parent will request a projection
				-- before the parent has been projected so we need to cache one
				if not parent_projection then
					parent:project(identifier, camera, viewport)
					parent_projection = parent.projections[identifier]
				end

				ox, oy, oz = unpack(parent_projection)

			end
			]]--

			projection[1] = x + cx - cx * reciprocal + ox
			projection[2] = y + cy - cy * reciprocal + oy
		elseif positioning == 'fixed' then -- fixed in viewport coordinate space, no projection
			projection[1] = x + cx
			projection[2] = y + cy
		elseif positioning == 'sticky' then -- fixed in viewport coordinate space but with anchoring
			local alignment = self.alignment or {}
			local vl, vr, vt, vb = unpack(viewport)
			local h, v, ox, oy = unpack(alignment)

			-- h, v are 0 .. 1 ratios applied to the viewport size
			-- ox, oy are pixel offset units

			h = h or 0
			v = v or 0
			ox = ox or 0
			oy = oy or 0

			local px = vl + (vr - vl) * h
			local py = vt + (vb - vt) * v

			projection[1] = x + px + ox + cx
			projection[2] = x + py + oy + cy
		end

		-- todo
		-- inform when this object is culled here
		-- since that can be useful for choosing when to remove something

		projections[identifier] = projection
		self.projections = projections

	end,

	context = function(self, projection, identifier)

		-- this isn't a very good solution since it is not very clear what is being passed around

		local angle = self.angle
		local scale = self.scale
		local origin = self.origin
		local shear = self.shear
		return identifier, projection, angle, scale, origin, shear

	end,

	distance = function(self, target)
		local x, y = unpack(self.position)
		local tx, ty = unpack(target.position)
		return tx - x, ty - y
	end,

	-- make bound, (change name of this method)
	_prepare = function(self)

		--[[
			we need a way to check if this bound is still valid
			and return early if it is
		]]--

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

		return bound

	end,

	-- this needs to use composite bounds
	-- this is a pretty bad name for this method
	debug = function(self, identifier)

		lg.setLineWidth(1)

		-- draws the bound of an object
		local f = function(object)
			local bound = object.bound
			if bound then
				local projection = object.projections[identifier]
				if projection then

					local edges = bound.edges
					local polygon = bound.polygon
					local circle = bound.circle
					local x, y, z = unpack(projection)
					local fudging = object.fudging or 1
					local w, h = edges[2] - edges[1], edges[4] - edges[3]

					-- translate the points to the projection
					-- this is a hilariously way of doing this
					local points = map(function(i,v) return v + projection[((i % 2) + 1) % 2 + 1] end, polygon)

					-- draw the collision modes
					lg.setColor(255, 255, 255, 100)
					--lg.rectangle('line', x + edges[1], y + edges[3], w, h)
					--lg.polygon('line', unpack(points))

					-- seperate the circles etc etc
					-- let this be configured more nicely
					local cx, cy, r = unpack(circle)
					local r = r
					lg.setColor(255, 255, 255)
					lg.circle('line', x + cx, y + cy, r)
					lg.setColor(255, 255, 255, 155)
					lg.circle('line', x + cx, y + cy, r * fudging)

					--lg.print(tostring(self.type), x + 10, y - 7)

					-- draw origin
					--lg.setColor(255, 255, 255, 155)
					--lg.circle('line', x, y, 6)

				end

			end
		end


		-- is there a cleaner way of achieving this?
		-- how do I abstract this correctly?
		-- what is common between the debug draw and the cull check?

		local overrides = self.overrides
		local composite = overrides and overrides.bound or nil
		if composite then
			for _,child in ipairs(composite) do
				f(child)
			end
		else
			f(self)
		end

		-- everywhere that uses bounds will need to include composite bounds?
		
	end,

	-- @todo use composite bounds (and possible different joining styles)
	-- this needs to use composite bounds
	-- better name, since this doesn't denote that it is a point test
	-- contains might be better
	intersecting = function(self, identifier, tx, ty, how)

		-- returns true if x/y is inside of the objects projection/bound
		-- for that identifier

		local projections = self.projections
		local projection = projections[identifier]

		if projection then

			local px, py, pz = unpack(projection)
			local bound = self.bound
			local fudging = self.fudging or 1

			local how = how or 'circle'
			-- decide on method
			if how == 'circle' then

				local circle = bound.circle
				local cx, cy, r = unpack(circle)
				local x = px + cx
				local y = py + cy
				local r = r * fudging

				-- allow for fudging with this
				local inside = (math.abs(tx - x) < r) and (math.abs(ty - y) < r)
				
				return inside

			-- temp override polygon test with rectangle...
			elseif how == 'rectangle' or how == 'polygon' then

				local edges = bound.edges
				local w, h = edges[2] - edges[1], edges[4] - edges[3]
				local x = px + edge[1]
				local y = py + edge[3]

				-- test rectangle

			elseif how == 'polygon' then

				-- test polygon
				-- lease efficient

			end

			-- composite? (polygon + circle)

		
			-- use circles by default? doesn't make a TON of sense

		end

	end,

	join = function(self, parent)
		self.parent = parent
	end,

	_clone = function(self)

		-- @todo fix this cloning
		-- so that object properties and methods are correctly transfered

		error('cloning is not implemented')
		
		local clone = class.clone(self)
		clone = class.include(self, clone)

		local status = ('%s'):format(type(clone.update))
		print(status)
		if not clone.update then
			error('update does not exist')
		end

		--clone._initialized = false

		local key = self._manager:register(clone)

		local status = ('clone %s, self %s'):format(clone._key, self._key)
		--print(status)

		return clone

	end,

	_destroy = function(self)
		--self._manager:release(self._key)
		self._manager:release(self)
	end,
}

