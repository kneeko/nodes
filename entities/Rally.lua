Rally = class{
	init = function(self, parent)
		self._type = 'rally'

		self.position = {0, 0, 0.85}
		self.positioning = 'relative'

		self.overrides = {parallax = 1}
		self.parent = parent

		self.timer = math.pi * 2 - math.pi / 2

		getManager():register(self)
	end,

	update = function(self, dt)

		-- create a new bezier
		local position = self.position
		local node = self.parent

		local identifier = self.identifier

		if identifier then
			local px, py = unpack(position)

			-- from position
			local fx, fy = unpack(node.position)

			-- to position
			local tx = fx + px
			local ty = fy + py

			-- call searches from the parent graph
			local graph = node._graph
			local from = graph:get_tile(identifier, fx, fy)
			local to = graph:get_tile(identifier, tx, ty)
			local path = graph:path(from, to)

			if path then

				-- build vertices from a sequence of tiles
				--local l, r, t, b
				local vertices = {}
				for i,tile in ipairs(path) do

					local x, y

					if i == 1 then
						x, y = fx, fy
					elseif i < #path then
						local position = tile.position
						x, y = unpack(position)
					else
						x, y = tx, ty
					end

					--[[
					l = l and math.min(l, x) or x
					r = r and math.max(r, x) or x
					t = t and math.min(t, y) or y
					b = b and math.max(b, y) or y
					--]]

					table.insert(vertices, x)
					table.insert(vertices, y)

				end
				-- special case, path is 1 tile long, so use start and end point
				if #vertices < 4 then
					vertices = {fx, fy, tx, ty}
				end

				self.path = path
				self.vertices = smooth(vertices)

			end

		end



	end,

	start = function(self)

		-- start moving towards rally

	end,

	set = function(self, x, y)

		local position = self.position
		position[1] = x
		position[2] = y

	end,

	move = function(self, dx, dy)

		local position = self.position
		position[1] = dx and position[1] + dx or position[1]
		position[2] = dy and position[2] + dy or position[2]

	end,

	draw = function(self, ...)
	
		local position = ...
		local x, y = unpack(position)
		if x ~= 0 and y ~= 0 then

			lg.setColor(255, 255, 255)
			lg.circle('line', x, y, 12)
		end

		local parent = self.parent
		local px, py = unpack(parent.position)
		lg.setColor(255, 255, 255)
		--lg.line(x, y, px, py)
		
		local vertices = self.vertices
		if vertices then
			lg.setColor(255, 255, 255)
			lg.line(vertices)
		end

	end,

	-- could this have a method where it is passed the parent position
	-- and moves towards it?

	-- this could contain a method to find suitable checkpoints for navigating the meshes?
	-- boy this gets incredibly complicated 
	--[[

	get traversable nodes
	-- selecting a node
	-- selecting a unit
	-- a port is open when two nodes are both accessible
		-- can I do a* on ports?

	-- ports can be owned by multiple tiles
	-- but it is certainly easy to generate the ports when refreshing the tile
	-- including their actual worldspace position!

	]]--

}