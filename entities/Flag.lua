Flag = class{
	init = function(self, parent)
		self.type = 'flag'
		-- has n parents
		self.position = {0, -7, 0.8}
		self.scale = {1, 1}

		self.height = 0
		self.radius = 0
		self.size = {10, 10}
		self.fudging = 5

		self.positioning = 'relative'
		self.overrides = {parallax = 1}

		self.callbacks = {'inputpressed', 'inputreleased'}
		self.parent = parent

		self.tiles = {}
		self.sources = {}

		getManager():register(self)
	end,

	update = function(self, dt)

		local sources = self.sources
		local n = 0
		for id, source in pairs(sources) do

			n = n + 1
			local x, y, pressure = source.source()

			local dy = (y - source.start) * 0.5
			dy = math.max(dy, 0)

			local requirement = 32
			local height = math.min(dy, requirement)
			self.height = easing.outCubic(height, 0, requirement, requirement)
			local radius = easing.inCubic(dy, 0, 6, requirement)
			self.radius = math.min(radius, 6)

			if self.height >= requirement then

				-- toggle and send to others
				--getManager().objects[self._key]:toggle()
				--self:toggle()
				self.parent:toggle()
				self.raised = true
				--client:broadcast(self._key)
				sources[id] = nil

			end
		end

		if n == 0 and not self.raised then
			self.height = self.height - (self.height) * dt * 8
			self.radius = self.radius - (self.radius) * dt * 5
		end

	end,

	draw = function(self, ...)

		local position = ...
		local x, y, z = unpack(position)
		lg.setColor(255, 255, 255)

		local height = self.height
		lg.line(x, y, x, y - height)

		local radius = self.radius


		lg.setColor(255, 149, 0)
		lg.circle('fill', x, y - height, radius)

		lg.setColor(255, 255, 255, 130)
		lg.circle('line', x, y - height, radius)
		--lg.print(self.label .. ', #' .. #self.tiles, x, y + 10)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source)

		local position = self.position

		if tonumber(id) or id == 'l' then 
		-- change this name
			if self:intersecting(identifier, x, y) and not self.raised then

				local sources = self.sources
				sources[id] = {
					start = y,
					source = source,
				}

			end
		end

	end,

	inputreleased = function(self, identifier, x, y, id, pressure)

		local sources = self.sources
		sources[id] = nil

	end,
}