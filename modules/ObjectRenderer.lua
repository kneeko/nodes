ObjectRenderer = class{
	init = function(self, objects, sorter)
		self.objects = objects
		self.sorter = sorter
		self.queue = {}
	end,

	update = function(self)
		-- project all the objects here
		-- determine if they will be culled
		-- supporting multiple viewports here becomes pretty tedious
		-- cameras should have a unique identifier

		local queue = self.queue

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
					projection = object:project(camera, viewport)
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
					-- put key in queue
					-- we also need to remember what viewport this came from
				end
			end
		end

	end,
	
	draw = function(self, camera, viewport)

		local objects = self.objects
		local queue = self.queue

		-- viewports
		



		--[[
		local objects = self.objects
		local sorter = self.sorter

		-- get the latest drawstack
		local stack = sorter:get() or {}

		-- camera position and viewport bound
		local cx, cy, cz = unpack(camera)
		local vl, vr, vt, vb = unpack(viewport)

		-- transform the viewport bound to worldspace using camera position
		local cl = vl + cx
		local cr = vr + cx
		local ct = vt + cy
		local cb = vb + cy

		for i, key in ipairs(stack) do
			local object = objects[key]
			if object then
				local visible, projection
				if object.visible then
					projection = object:project(camera, viewport)
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
					-- context() provides an easier way to pass a variable # of args for use
					-- inside of the object's draw method while giving the object itself
					-- control over what default values it should return
					local context = function() return object:context(projection) end
					object:draw(context())
					object:debug(projection)
				end
			end
		end
		]]--

	end,
}