Cat = class{
	init = function(self)

		self._type = 'cat'
		
		local x = 0
		local y = 0

		self.position = {x, y, 0.7}
		self.overrides = {parallax = 1}

		self.hp = 10

		self.origin = {0.5, 0.5}

		self.size = {1, 1}
		self.scale = {40, 40}

		self.efficiency = 0.3
		self.capacity = 60

		if math.random() > 0.4 then
			self.efficiency = 0.6
		end
		local variance = 15
		local color = {
			211 - variance + variance * math.random(),
			54 - variance + variance * math.random(),
			130 - variance + variance * math.random(),
		}
		self.color = color

		self.callbacks = {'inputpressed'}

		self.includes = {Collidable}

		manager:register(self)
	end,
	update = function(self, dt)

	end,

	draw = function(self, ...)
		local position, _, _, _, _, identifier = ...
		local x, y = unpack(position)

		local r = self.scale[1] * 0.5

		lg.setColor(0, 0, 0, 20)
		lg.circle('fill', x, y + 4, r, 16)

		local color = self.color
		lg.setColor(color)
		lg.circle('fill', x, y, r, 64)

		lg.setColor(255, 255, 255, 100)
		lg.circle('line', x, y, r, 28)


		lg.setColor(255, 255, 255)
		local s = ("%s%%"):format(math.floor(self.scale[1] / self.capacity * 100))
		lg.print(self._key, x, y)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source)

		if self:intersecting(identifier, x, y, 'circle') then

			if id == 'l' then
				self:emit()

				--local clone = Cat()
				--clone.parent = self.parent
				--clone.positioning = self.positioning
				

			end

			-- drag and drop to create a new cat?
			if id == 'r' then
				self:destroy()
			end

		end

	end,

	grow = function(self, n)
		local scale = self.scale
		local capacity = self.capacity
		local growth = math.abs(1 - (math.min(scale[1] + n, capacity) / capacity)) * n
		self.scale[1] = scale[1] + growth
		self.scale[2] = scale[2] + growth

	end,

	emit = function(self)

		self:grow(-20)

		-- emit a pulse along the route
		local routes = self.routes or {}
		for _,route in ipairs(routes) do
			route:emit(self)
		end

	end,

	destroy = function(self)

		-- this should actually be responsible for destroying the other route?
		-- right now i'm really making twice as many routes as I need
		-- just for convienience
		-- this both lowers and increases the mental burden a bit
		-- it would be better if routes could be traversed in two different directions

		local routes = self.routes or {}
		print('removing ' .. #routes .. ' routes')
		for i,route in ipairs(routes) do
			route:sever(self)
		end

		self:_destroy()
	end,
}