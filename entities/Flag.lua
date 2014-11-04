Flag = class{
	init = function(self, parent)
		self.type = 'node'
		-- has n parents
		self.position = {0, 0, 1}
		self.scale = {1, 1}

		self.positioning = 'relative'
		self.parent = parent

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
		lg.setColor(255, 0, 0)
		lg.line(x, y, x, y - 50)

		lg.setColor(101, 123, 131)
		--lg.print(self.label .. ', #' .. #self.tiles, x, y + 10)

	end
}