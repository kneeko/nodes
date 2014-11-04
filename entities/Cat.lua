Cat = class{
	init = function(self, step)
		self.type = 'cat'

		local graphic = lg.newImage('image.png')
		local w, h = graphic:getWidth(), graphic:getHeight()
		local scale = 2
		local step = step or 0
		local range = 10

		local x = 100 + (w + 15) * scale * (step % range)
		local y = 200 + (h + 15) * scale * math.floor(step / range)
		local z = 1 + 0.1 * step

		self.position = {x, y, z}

		graphic:setFilter('nearest', 'nearest')
		local w, h = graphic:getWidth(), graphic:getHeight()
		self.graphic = graphic

		self.size = {w, h}
		self.origin = {w*0.5, h*0.5}
		self.scale = {scale, scale}
		self.angle = 0
		self.timer = 0

		--self.positioning = 'ab'
		--self.alignment = {0.3, 0.3, 0, 0}

		-- callbacks to send to this object (input events)
		self.callbacks = {'mousepressed'}

		-- behaviours to include
		self.includes = {Collidable}

		-- register self to object manager
		-- how do we find out what manager this is?
		-- maybe there's a global getScene()?
		getManager():register(self)
	end,

	update = function(self, dt)
		
		--self.angle = self.angle + dt
		self.timer = self.timer + dt
		
		--self.position[2] = self.position[2] + math.sin(self.timer * math.pi) * dt * 100
		
		--self.position[3] = self.position[3] + math.sin(self.timer * math.pi) * dt

		--self.position[2] = 200 + 100 * math.sin(self.timer * math.pi)

		--self.scale[1] = 3 + 2 * math.sin(self.timer)
		--self.scale[2] = 5 * math.cos(self.timer)

		--self.scale[1] = 2 + math.sin(self.timer * math.pi)
		--self.scale[2] = 2 + math.sin(self.timer * math.pi)
	end,

	draw = function(self, ...)
		local position, angle, scale, origin, shear = ...
		local x, y, z = unpack(position)
		local sx, sy = unpack(scale)
		local ox, oy = unpack(origin)
		local kx, ky = unpack(shear)
		local graphic = self.graphic

		lg.setColor(255, 255, 255)
		lg.draw(graphic, x, y, angle, sx, sy, ox, oy, kx, ky)
		lg.print(self._key, x, y)

	end,

	mousepressed = function(self, mx, my, button)
		local bound = self.bound
		local edges = bound.edges
		local l, r, t, b = unpack(edges)
		local x, y, z = unpack(self.position)

		local missed = x + r < mx
			or x + l > mx
			or y + t > my
			or y + b < my

		if not missed then
			--self:destroy()
		end
	end,

}