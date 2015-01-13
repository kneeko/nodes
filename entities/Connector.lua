Connector = class{
	init = function(self)

		self._type = 'connector'

		local position = {0, 0, 0.6}
		local scale = {1, 1}
		local size = {16, 16}
		local origin = {8, 8}
		local positioning = 'relative'

		self._debug = true
		self.fudging = 1

		self.route = {}

		self.position = position
		self.scale = scale
		self.origin = origin
		self.size = size
		self.positioning = positioning

		self.overrides = {parallax = 1}

		manager:register(self)

	end,

	update = function(self, dt)

		local dragging = self.dragging
		if dragging then

			local ox, oy = unpack(dragging.origin)
			local cx, cy = unpack(dragging.cached)
			local x, y = dragging.source()

			local dx = x - cx
			local dy = y - cy

			local position = self.position
			position[1] = position[1] + dx
			position[2] = position[2] + dy

			dragging.cached[1] = x
			dragging.cached[2] = y

			local identifier = dragging.identifier
			local graph = self._graph

			-- use the actual object position rather than the tough position
			local projections = self.projections
			local projection = projections[identifier] or {x, y}
			local px, py = unpack(projection)
			local selected = graph:get_tile(identifier, px, py)

			if selected and selected ~= self.selected then
				-- new tile selected?
			end

			self.selected = selected

		end

		if not dragging then
			local position = self.position
			local x, y = unpack(position)
			local snappiness = 30
			position[1] = x - x * dt * snappiness
			position[2] = y - y * dt * snappiness
		end

	end,

	drag = function(self, source, identifier, id)

		local x, y = source()
		local dragging = {
			identifier = identifier,
			id = id,
			origin = {x, y},
			source = source,
			cached = {x, y},
		}

		-- todo
		-- key this by id
		self.dragging = dragging

	end,

	drop = function(self)

		self.dragging = nil

		local selected = self.selected

		self:migrate(selected)

		self.selected = nil

		-- maybe drop into a new tile? hmm

	end,

	migrate = function(self, destination)
		local parent = self.parent
		if destination and destination ~= parent then

			local position = self.position

			local tx, ty = unpack(destination.position)
			local px, py = unpack(parent.position)

			local dx = px - tx
			local dy = py - ty

			position[1] = position[1] + dx
			position[2] = position[2] + dy

			destination.terminal = self
			parent.terminal = nil
			self.parent = destination

		end
	end,

	draw = function(self, identifier, ...)

		local projection = ...

		local x, y = unpack(projection)

		

		local selected = self.selected
		if selected then
			local sx, sy = unpack(selected.projections[identifier])
			lg.setColor(255, 255, 255)
			lg.line(x, y, sx, sy)
		end

		local route = self.route
		local vertices = {}
		for _,node in ipairs(route) do
			local nx, ny = unpack(node.projections[identifier])
			vertices[#vertices + 1] = nx
			vertices[#vertices + 1] = ny
		end

		if #vertices >= 4 then
			lg.setColor(255, 255, 255, 200)
			lg.line(vertices)
		end

		local font = lg.getFont()
		local string = 'T' .. self._key
		local w, h = font:getWidth(string), font:getHeight(string)
		lg.setColor(255, 255, 255)
		lg.print(string, x - w*0.5, y - h*0.5)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, _, source)
		local hit = self:intersecting(identifier, x, y, 'circle')
		if hit and id == 'l' then
			self:drag(source, identifier, id)
			return true
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
}