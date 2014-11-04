Grid = class{
	init = function(self)
		self.type = 'grid'

		local w, h = lg.getWidth(), lg.getHeight()

		local x = 0
		local y = 0
		local z = 1
		local scale = 1

		self.position = {x, y, z}
		self.size = {w, h}
		self.scale = {scale, scale}
		self.angle = 0
		self.timer = 0

		getManager():register(self)
	end,

	update = function(self, dt)
	end,

	draw = function(self, ...)

		local position, angle, scale, origin, shear = ...
		local x, y, z = unpack(position)
		local sx, sy = unpack(scale)
		local kx, ky = unpack(shear)
		
		local size = self.size
		local w, h = unpack(size)

		local interval = 100

		for i = 0, math.floor(w / interval) do
			local lx = x + i * interval
			lg.setColor(255, 255, 255, 100)
			lg.line(lx, 0, lx, h)
		end

		for i = 0, math.floor(h / interval) do
			local ly = y + i * interval
			lg.setColor(255, 255, 255, 100)
			lg.line(0, ly, w, ly)
		end



		lg.setColor(255, 100, 100)
		lg.rectangle('line', x, y, w, h)
		lg.print(self._key, x, y)

	end,

}