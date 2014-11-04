ObjectRenderer = class{
	init = function(self, objects, sorter)
		self.objects = objects
		self.sorter = sorter
		self.queue = {}
	end,

	update = function(self)
		

	end,

	prepare = function(self, identifier, camera, viewport)
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
		local vl, vr, vt, vb = unpack(viewport)

		-- transform the viewport bound to worldspace using camera position
		local cl = vl + cx
		local cr = vr + cx
		local ct = vt + cy
		local cb = vb + cy

		-- get each camera and viewport here instead
		for i, key in ipairs(stack) do
			local object = objects[key]
			if object then
				local visible, projection
				if object.visible then
					-- use identifier to seperate the different projections
					object:project(identifier, camera, viewport)
					local projection = object.projections[identifier]
					local edges = object.bound.edges
					local l, r, t, b = unpack(edges)
					local x, y, z = unpack(projection)
					local culled = x + r < cl
						or x + l > cr
						or y + t > cb
						or y + b < ct
					visible = (not culled) and not (z < 0)
				end
				if visible then
					queue[identifier][i] = key
				end
			end
		end
	end,
	
	draw = function(self)
		local objects = self.objects
		local queue = self.queue
		for identifier,keys in pairs(queue) do
			for _,key in ipairs(keys) do
				local object = objects[key]
				local projection = object.projections[identifier]
				object:draw(object:context(projection))
				object:debug(projection)
			end
		end
	end,
}