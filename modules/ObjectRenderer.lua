ObjectRenderer = class{
	init = function(self, objects, sorter)
		self.objects = objects
		self.sorter = sorter
		self.queue = {}
	end,

	prepare = function(self, identifier, camera, bound)

		-- project all the objects here
		-- determine if they will be culled
		-- supporting multiple viewports here becomes pretty tedious
		-- cameras should have a unique identifier

		local queue = self.queue
		queue[identifier] = queue[identifier] or {}

		local objects = self.objects
		local sorter = self.sorter

		-- changing this to directly access the sorter seems to solve the problem
		local stack = sorter.stack or {}

		-- get all the viewports here and then do this in a for loop
		local cx, cy, cz = unpack(camera)
		local vl, vr, vt, vb = unpack(bound)

		-- transform the bound to worldspace using camera position
		-- todo expand as camera zoom changes?
		local cl = vl + cx
		local cr = vr + cx
		local ct = vt + cy
		local cb = vb + cy

		-- get each camera and viewport here instead
		local count = 1
		for i, key in ipairs(stack) do
			local object = objects[key]
			if object then
				local visible, projection
				if object._visible then

					-- @todo move this function to the entity class
					-- nico 12/3/2014
					local f = function(object)
						object:project(identifier, camera, bound)
						local projection = object.projections[identifier]
						if not object.bound then
							if object.prepare then
								object:prepare()
							elseif object._prepare then
								object:_prepare()
							end
						end
						local edges = object.bound.edges
						local l, r, t, b = unpack(edges)
						local x, y, z = unpack(projection)
						local culled = x + r < cl
							or x + l > cr
							or y + t > cb
							or y + b < ct
						return (not culled) and (z >= 0)
					end

					-- @todo create an iterator function for this inside the entity class
					-- since this can be shared for debug drawing
					-- nico 12/3/2014
					local overrides = object.overrides
					local composite = overrides and overrides.bound or nil
					visible = f(object)
					if composite then
						for _,child in ipairs(composite) do
							visible = (not visible) and f(child) or (visible)
						end
					end
					
				end
				if visible then
					queue[identifier][count] = key
					count = count + 1
					object._queued = true
				end
			end
		end

		-- trim the queue
		if #queue[identifier] > count then
			for i = count + 1, #queue[identifier] do
				queue[identifier][i] = nil
			end
		end

	end,

	flush = function(self, identifier)
		local queue = self.queue
		queue[identifier] = nil
	end,
	
	-- this is called on a per-viewport basis
	draw = function(self, identifier, camera, bound)
	
		local objects = self.objects
		local queue = self.queue
		local count = 0
		local drawn = {}
		local keys = queue[identifier] or {}
		for _,key in ipairs(keys) do
			if not drawn[key] then
				local object = objects[key]
				if object then
					local projection = object.projections[identifier]
					if object.draw then
						object:draw(object:context(projection, identifier))
					end
					if object._debug then
						object:debug(identifier)
					end
					count = count + 1
					drawn[key] = true
				else
					local msg = ('a nil with key %s was passed into the drawstack'):format(key, type(object))
					--print(msg)
				end
			else
				local msg = ('key %s was drawn twice'):format(key)
				--print(msg)
			end
		end

		-- draw viewport outline for debugging
		local x, y, z = unpack(camera)
		local l, r, t, b = unpack(bound)
		local inset = -1
		local dx = l + x + inset
		local dy = t + y + inset
		local dw = r - l - inset*2
		local dh = b - t - inset*2
		lg.setColor(255, 255, 255, 100)
		--lg.rectangle('line', dx, dy, dw, dh)

	end,
}