Token = class{
	init = function(self, parent)
		self._type = 'token'

		self.position = {0, 0, 0.95}
		self.overrides = {parallax = 1}
		self.positioning = 'relative'
		self.parent = parent

		self.scale = {2, 2}
		self.size = {30, 30}
		self.origin = {15, 15}

		-- inherited culling?
		-- maybe an override? this could get a little complicated

		-- temp visual flair
		self.hover = 0
		self.timer = 0

		getManager():register(self)
	end,

	update = function(self, dt)
	
		self.timer = self.timer + dt
		self.hover = math.sin(self.timer * math.pi)
	end,

	draw = function(self, ...)

		local position = ...
		local x, y = unpack(position)
		lg.setLineWidth(2)


		local hover = self.hover

		lg.setColor(0, 0, 0, 40)
		lg.circle('line', x, y, 15, 16)

		lg.setColor(255, 255, 255)
		lg.circle('line', x, y - 6 - hover, 15, 32)

		lg.setLineWidth(1)

	end,

	inputpressed = function(self, identifier, x, y, id, pressure, source)
	end,

	inputreleased = function(self, identifier, x, y, id, pressure)
	end,

}