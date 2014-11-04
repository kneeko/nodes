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
		local stack = sorter:get() or {}

		-- get all the viewports here and then do this in a for loop
		local cx, cy, cz = unpack(camera)
		local vl, vr, vt, vb = unpack(bound)

		-- transform the bound to worldspace using camera position
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
				if object.visible then
					object:project(identifier, camera, bound)
					local projection = object.projections[identifier]
					local edges = object.bound.edges
					local l, r, t, b = unpack(edges)
					local x, y, z = unpack(projection)
					local culled = x + r < cl
						or x + l > cr
						or y + t > cb
						or y + b < ct
					visible = (not culled) and (z > 0)
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
	
	draw = function(self, identifier, camera, bound)
	
		local objects = self.objects
		local queue = self.queue
		local count = 0
		local keys = queue[identifier] or {}
		for _,key in ipairs(keys) do
			local object = objects[key]
			local projection = object.projections[identifier]
			object:draw(object:context(projection))
			object:debug(projection)
			count = count + 1
		end

		local x, y, z = unpack(camera)
		local l, r, t, b = unpack(bound)
		lg.setColor(255, 255, 255, 100)
		lg.rectangle('line', x - 1, y - 1, r - l + 2, b - t + 2)

		lg.setColor(255, 255, 255)
		lg.print(count, 15, 15)

	end,
}