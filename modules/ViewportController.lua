ViewportController = class{
	init = function(self, v, step, scale, interaxial)

		local identifier = (os.time()) .. '-' .. math.floor(math.random() * 1000)
		self._identifier = identifier

		print('Created a viewport with id: ' .. identifier)

		local ww, wh = lg.getWidth(), lg.getHeight()
		local w = ww * scale
		local h = wh

		local bound = {0, w, 0, h}
		local position = {step * interaxial, 0, 1}

		self.step = step * ww
		self.position = position
		self.bound = bound
		self.angle = 0

		-- v is the number of viewports, i would be better off now having this as locked in stone...
		self.camera = Camera(v)
		self.canvas = lg.newCanvas(w, h)

		self.timer = 0
	end,

	update = function(self, dt)

		
		self.timer = self.timer + dt

		local radius = 50

		--self.position[1] = self.position[1] + math.cos(self.timer) * radius * dt
		--self.position[2] = math.sin(self.timer) * radius
		--self.position[3] = 0.75 + 0.25 * math.sin(self.timer * 3)

		local camera = self.camera
		local l, r, t, b = unpack(self.bound)
		local w, h  = r - l, b - t
		local x, y, z = unpack(self.position)

		-- hmm, how does this get positioned?
		-- this affects the actual world position stuff, so don't change this per camera...
		local ox = lg.getWidth() * 0.5
		local oy = lg.getHeight() * 0.5
		local angle = self.angle
		camera:set(x + ox, y + oy, z)
		camera:rotate(angle)

	end,

	draw = function(self, scene)

		local position = self.position
		local bound = self.bound
		local camera = self.camera
		local canvas = self.canvas

		lg.setCanvas(canvas)
		canvas:clear()
		
		camera:attach()
		scene:draw(position, bound)
		camera:detach()

		local x, y, z = unpack(position)
		local s = 'camera (' .. math.floor(x) .. ', ' .. math.floor(y) .. ', ' .. z .. ')'
		s = s .. '\n' .. lt.getFPS() .. ' fps'
		lg.print(s, 15, 15)

		lg.setCanvas()

		lg.setColor(255, 255, 255)
		lg.setBlendMode('premultiplied')
		local step = self.step
		lg.draw(canvas, step)
		lg.setBlendMode('alpha')

	end,

	prepare = function(self, scene)

		local identifier = self._identifier
		local position = self.position
		local bound = self.bound
		scene:prepare(identifier, position, bound)

	end,

	project = function(self, x, y)
		local camera = self.camera
		return camera:project(x, y)
	end,

	translate = function(self, dx, dy, dz)
		local position = self.position
		position[1] = dx and position[1] + dx or position[1]
		position[2] = dy and position[2] + dy or position[2]
		position[3] = dz and position[3] + dz or position[3]
	end,

	rotate = function(self, dr)
		local angle = self.angle
		self.angle = dr and angle + dr or angle
	end,
}