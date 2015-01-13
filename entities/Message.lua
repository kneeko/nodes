Message = class{

	init = function(self)

		self._type = 'message'

		self.string = 'message'

		self.scale = {1, 1}
		self.size = {1, 1}
		self.origin = {0.5, 0.5}
		self.position = {0, 0, 0.5}

		self.overrides = {parallax = 1}
		self.positioning = 'relative'

		self.timer = 0
		self.duration = 1

		manager:register(self)

	end,

	update = function(self, dt)
		local timer = self.timer
		local duration = self.duration
		self.timer = math.min(timer + dt, duration)
		if self.timer == duration then
			self:_destroy()
		end
	end,

	draw = function(self, identifier, ...)
		local projection = ...
		local x, y = unpack(projection)
		local string = self.string
		local font = lg.getFont()
		local w, h = font:getWidth(tostring(string)), font:getHeight(tostring(string))

		lg.setColor(255, 255, 255)
		lg.print(tostring(string), x, y, 0, 1, 1, w*0.5, h*0.5)

	end,

}