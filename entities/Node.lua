-- a node could know the distance
-- and have a traverse function that returns a position?
-- hmmm

-- do i want to support branching on a node?
-- probably

Node = class{
	init = function(self)

		self._type = 'node'

		local position = {0, 0, 0.6}
		local scale = {1, 1}
		local size = {12, 12}
		local origin = {6, 6}
		local positioning = 'relative'

		--self._debug = true
		self.fudging = 2

		-- neighbors will always contain to and from
		-- in no particular order
		local neighbors = {}
		self.neighbors = neighbors

		self.rigidity = 15

		-- todo
		-- convert this to a Route object
		self.path = {}

		self.position = position
		self.scale = scale
		self.origin = origin
		self.size = size
		self.positioning = positioning

		self.overrides = {parallax = 1, bound = neighbors}
		self.callbacks = {'inputpressed', 'inputreleased'}

		self.width = 2
		self.radius = 30

		manager:register(self)

	end,

	update = function(self, dt)

	end,

	-- do I want an extra function here?
	-- prepare?

	draw = function(self, identifier, ...)

		local projection = ...
		local x, y = unpack(projection)

		local font = lg.getFont()
		local string = 'N' .. self._key
		local w, h = font:getWidth(string), font:getHeight(string)
		lg.setColor(255, 255, 255, 100)
		lg.setLineWidth(1)
		lg.circle('line', x, y, 3)
		--lg.print(string, x - w*0.5, y - h*0.5 + h)

		-- i will want to draw a segment here
		-- rather than entirely to the destination and not at all from the source
		-- to / from makes sense for this until I start to have multiple destinations...
		-- well, maybe it is ok either way
		
		local progress = 0.5
		local width = self.width
		local radius = self.radius

		lg.setColor(255, 255, 255, 100)
		lg.setLineWidth(width)

		local vertices = {}
		local neighbors = self.neighbors

		-- very hacky
		-- i need a general solution for showing all of the branches to and from this node
		if #neighbors == 2 then
			neighbors = {neighbors[1], self, neighbors[2]}
		else
			neighbors = {neighbors[1], self}
		end

		-- if we have more than two neighbors, we will need to
		-- cache the segments for each from .. to pair

		for i,node in ipairs(neighbors) do

			local node_projection = node.projections[identifier]
			if node_projection then
				local nx, ny = unpack(node_projection)

				-- maybe compute these vertices in update
				-- and store them like vertices[identifier]?
				-- the problem is that projections are always going to we prepared after update
				-- so that makes everything 1 frame late

				local px = x + (nx - x) * progress
				local py = y + (ny - y) * progress


				vertices[#vertices + 1] = px
				vertices[#vertices + 1] = py

				--lg.line(x, y, px, py)
			end
		end

		vertices = smooth(vertices, radius)

		-- map these vertices to allow for smooth interpolation between 0 and 1
		-- and know the distance so we can decide on a consistant speed

		if #vertices >=4 then
			lg.line(vertices)
		end

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, _, source)
		local hit = self:intersecting(identifier, x, y, 'circle')
		if hit and id == 'l' then

			--[[
			local parent = self.parent
			local terminal = Terminal()

			terminal.parent = parent
			terminal:drag(source, identifier, id)
			terminal._graph = self._graph
			terminal._well = self
			terminal:connect(parent)

			parent.terminal = terminal
			return true
			]]--

			local ping = Ping()
			ping:visit(self)

		end

		if hit and id == 'r' then
			
		end
	end,

	inputreleased = function(self, identifier, x, y, id, pressure)

		local dragging = self.dragging
		if dragging then
			if dragging.id == id then
				self:drop()
			end
		end

	end,

	add = function(self, node)

		-- a node could be both in to and neighbors?
		-- this way i can seperate some parts of my logic

		local neighbors = self.neighbors
		local exists
		for _,neighbor in ipairs(neighbors) do
			if neighbor == node then
				exists = true
			end
		end
		if not exists then
			table.insert(neighbors, node)
			-- add this node to the refs?
		end
	end,

	remove = function(self, node)
		local neighbors = self.neighbors
		for index,neighbor in ipairs(neighbors) do
			if neighbor == node then
				table.remove(neighbors, index)
			end
		end
	end,

	destroy = function(self)
		-- take care of dereferencing self?
		-- remove self form any place that it is references
		local neighbors = self.neighbors

		for _,neighbor in ipairs(neighbors) do
			neighbor:remove(self)
		end

		local parent = self.parent
		if parent.node == self then
			parent.node = nil
		end

		self:_destroy()
	end,
}