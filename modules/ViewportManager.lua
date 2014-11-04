ViewportManager = class{
	init = function(self, n)
		local viewports = {}
		local v = n or 1
		local interaxial = -100
		for i = 1, v do
			local step = (i - 1) / v
			local w = 1 / v
			viewports[#viewports + 1] = ViewportController(v, step, w, interaxial)
		end
		self.viewports = viewports

		-- used for reinit on resize
		self.n = n

		-- experimental camera movement
		self.panning = false
		self.zooming = false
	end,

	update = function(self, dt)

		local input = self.input or {}
		local ix, iy = unpack(input)
		local mx, my = lm.getPosition()
		local dx, dy, dz, dr = 0, 0, 0, 0
		self.input = {mx, my}

		local panning = self.panning
		local rotating = self.rotating
		local zooming = self.zooming

		if panning then
			dx = ix and ix - mx or 0
			dy = iy and iy - my or 0
		end

		if zooming then
			dz = iy and iy - my or 0
			dz = dz * 0.01
		end

		if rotating then
			dr = ix and ix - mx or 0
			dr = dr * 0.005
		end

		local viewports = self.viewports
		local scene = self.scene
		for i = 1, #viewports do
			local viewport = viewports[i]
			-- TODO fix the angled translation
			viewport:rotate(dr)
			local angle = viewport.angle
			local x = dx-- * math.cos(angle) + dy * math.sin(angle)
			local y = dy-- * math.sin(angle) + dy * math.cos(angle)
			local z = dz
			viewport:translate(x, y, z)
			viewport:update(dt)
			viewport:prepare(scene)
		end
	end,

	draw = function(self, scene)
		local viewports = self.viewports
		for i = 1, #viewports do
			viewports[i]:draw(scene)
		end
	end,

	set = function(self, n)
		self:init(n)
	end,

	resize = function(self)
		self:init(self.n)
	end,

	project = function(self, x, y)
		local viewport = self.viewports[1]
		return viewport:project(x, y)
	end,

	mousepressed = function(self, x, y, button)
	end,

	mousereleased = function(self, x, y, button)
	end,

	keypressed = function(self, key, code)
		if key == ' ' then
			self.panning = true
		end
		if key == 'lctrl' then
			self.zooming = true
		end
		if key == 'lshift' then
			self.rotating = true
		end
	end,

	keyreleased = function(self, key, code)
		if key == ' ' then
			self.panning = false
		end
		if key == 'lctrl' then
			self.zooming = false
		end
		if key == 'lshift' then
			self.rotating = false
		end
	end,
}