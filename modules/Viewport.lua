Viewport = class{
	init = function(self, v, step, stretch, interaxial)

		-- this probably needs another name
		-- maybe just Viewport

		local identifier = Identifier()
		self._identifier = identifier

		print('Created a viewport with id: ' .. identifier:get())

		local ww, wh = lg.getWidth(), lg.getHeight()
		local w = ww * stretch
		local h = wh

		local bound = {0, w, 0, h}
		local position = {step * interaxial, 0, 2}

		self.step = step * ww
		self.position = position
		self.bound = bound
		
		self.angle = (math.pi / 6)
		self.angle = 0

		-- v is the number of viewports, i would be better off now having this as locked in stone...
		self.total = v
		self.camera = Camera(v)
		self.canvas = lg.newCanvas(w, h)
		self.timer = 0

		-- these rules probably need to take into account zoom
		-- if I do that I will need to give them a way to be evaluated
		-- or just use the local reference to the position here

		local ruleset = {
			[1] = {
				--threshold = {-w*0.5 , w*0.5},
				--limit = {-w*2, w*2},
				filter = function(delta)
					local z = position[3]
					local reciprocal = 1 / z
					local filtered = delta * reciprocal
					return filtered
				end,
			},
			[2] = {
				--threshold = {-h*0.25 , h*0.25},
				--limit = {-h*4, h*4},
				filter = function(delta)
					local z = position[3]
					local reciprocal = 1 / z
					local filtered = delta * reciprocal
					return filtered
				end,
			},
			[3] = {
				threshold = {0.25 , 3},
				limit = {0.05, 4},
				filter = function(delta)
					return delta
				end,
			}
		}
		self.limiter = Limiter(position, ruleset)

		-- debug
		self.points = {}

	end,

	update = function(self, dt)

		

		local limiter = self.limiter
		limiter:update(dt)

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
		lg.setColor(255, 255, 255)
		lg.print(s, 15, 15)

		lg.setCanvas()

		lg.setColor(255, 255, 255)
		lg.setBlendMode('premultiplied')

		local step = self.step
		lg.draw(canvas, step)
		lg.setBlendMode('alpha')

		local status = position[1] .. ', ' .. bound[1]
		--lg.print(status, 15, 60)

		local limiter = self.limiter
		--limiter:draw()

	end,

	prepare = function(self, scene)

		local identifier = self._identifier:get()
		local position = self.position
		local bound = self.bound
		scene:prepare(identifier, position, bound)

	end,

	translate = function(self, dx, dy)

		local limiter = self.limiter
		limiter:shift(1, dx)
		limiter:shift(2, dy)

	end,

	zoom = function(self, dz)

		if dz then
			local limiter = self.limiter
			limiter:shift(3, dz)
		end

	end,

	rotate = function(self, dr)
		local angle = self.angle
		self.angle = dr and angle + dr or angle
	end,
}