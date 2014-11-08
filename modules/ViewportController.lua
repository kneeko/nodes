ViewportController = class{
	init = function(self, v, step, stretch, interaxial)

		local identifier = Identifier()
		self._identifier = identifier

		print('Created a viewport with id: ' .. identifier:get())

		local ww, wh = lg.getWidth(), lg.getHeight()
		local w = ww * stretch
		local h = wh

		local bound = {0, w, 0, h}
		local position = {step * interaxial, 0, 1}

		self.step = step * ww
		self.position = position
		self.bound = bound
		self.angle = 0

		-- v is the number of viewports, i would be better off now having this as locked in stone...
		self.total = v
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

		local position = self.position
		local x, y, z = unpack(position)
		
		-- update the bound
		local bound = self.bound
		local w, h = lg.getWidth(), lg.getHeight()

		-- scale the viewport bound by the reciprocal of the zoom
		-- in order to cull at the canvas edge
		local reciprocal = 1 / z
		local total = self.total
		local length = w * 0.5 * (1 / total)
		local height = h * 0.5

		local l = length - length * reciprocal
		local r = length + length * reciprocal
		local t = height - height * reciprocal
		local b = height + height * reciprocal

		bound[1] = l
		bound[2] = r
		bound[3] = t
		bound[4] = b

		-- update the camera position
		local camera = self.camera
		local ox = w * 0.5
		local oy = h * 0.5
		local angle = self.angle
		camera:set(x + ox, y + oy, z)
		camera:rotate(angle)

	end,

	draw = function(self, scene)

		local position = self.position
		local bound = self.bound
		local camera = self.camera
		local canvas = self.canvas
		local identifier = self._identifier:get()

		lg.setCanvas(canvas)
		canvas:clear()
		
		camera:attach()
		scene:draw(identifier, position, bound)
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

		local status = position[1] .. ', ' .. bound[1]
		lg.print(status, 15, 60)

	end,

	prepare = function(self, scene)

		local identifier = self._identifier:get()
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
		local reciprocal = 1 / position[3]

		-- do some processing on these values
		-- and also, once the manager tells us to lock (no active inputs)
		-- move back within soft bounds
		-- never move past hard bounds

		position[1] = (dx) and (position[1] + dx * reciprocal) or (position[1])
		position[2] = (dy) and (position[2] + dy * reciprocal) or (position[2])
		position[3] = (dz) and (position[3] + dz * reciprocal) or (position[3])

		-- temp hard caps
		position[3] = math.max(position[3], 0.4)
		position[3] = math.min(position[3], 2)


	end,

	rotate = function(self, dr)
		local angle = self.angle
		self.angle = dr and angle + dr or angle
	end,
}