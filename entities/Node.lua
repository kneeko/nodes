Node = class{
	init = function(self, x, y)
		self.type = 'node'
		-- has n parents
		self.position = {x, y, 1}
		self.scale = {1, 1}
		self.size = {12, 12}
		self.origin = {6, 6}

		self.tiles = {}

		getManager():register(self)
	end,

	update = function(self, dt)
	end,

	draw = function(self, ...)
		local position = ...
		local x, y, z = unpack(position)
		lg.setColor(42, 161, 152)
		lg.circle('fill', x, y, 6)

		lg.setColor(101, 123, 131)
		--lg.print(self.label .. ', #' .. #self.tiles, x, y + 10)

	end
}