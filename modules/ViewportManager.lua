ViewportManager = class{
	init = function(self, scene, n)

		self.scene = scene

		-- todo: make multiple viewports coherent
		local viewports = {}
		local v = n or 1
		local interaxial = -100
		for i = 1, v do
			local step = (i - 1) / v
			local w = 1 / v
			viewports[#viewports + 1] = Viewport(v, step, w, interaxial)
		end
		self.viewports = viewports

		-- used for reinit on resize
		self.n = n

		-- development camera zooming
		self.zooming = false

		local controller = ViewportController(scene, viewports)
		self.controller = controller

	end,

	update = function(self, dt)

		local controller = self.controller
		controller:update(dt)

		-- todo
		-- migrate these dev controls into viewportcontroller

		local input = self.input or {}
		local ix, iy = unpack(input)
		local mx, my = lm.getPosition()
		local dx, dy, dz, dr = 0, 0, 0, 0
		self.input = {mx, my}

		local panning = self.panning
		local rotating = self.rotating
		local zooming = self.zooming and lm.isDown('l')

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

		local controller = self.controller
		local cx, cy, cz = unpack(controller.interpolated)

		-- should the viewport have a limiter built in?
		-- that makes sense I guess

		-- send locks and unlocks?


		local viewports = self.viewports
		local scene = self.scene
		for i = 1, #viewports do
			-- TODO fix the angled translation
			--local x = cx-- + dx-- * math.cos(angle) + dy * math.sin(angle)
			--local y = cy-- + dy-- * math.sin(angle) + dy * math.cos(angle)
			--local z = cz-- + dz

			local x = cx
			local y = cy
			local z = cz + dz

			-- apply transformations to viewport
			local viewport = viewports[i]
			viewport:translate(x, y)
			viewport:zoom(z)
			viewport:rotate(dr)

			-- update the viewport bound and position using the limiter
			viewport:update(dt)
			
			-- prepare projections of scene objects for drawing
			viewport:prepare(scene)

		end
	end,

	draw = function(self)

		local scene = self.scene
		local viewports = self.viewports
		for i = 1, #viewports do
			viewports[i]:draw(scene)
		end

		-- controller debug
		local controller = self.controller
		--controller:draw()

	end,

	set = function(self, n)
		-- we need to clean up when this happens
		local scene = self.scene
		local viewports = self.viewports
		for i = 1, #viewports do
			local viewport = viewports[i]
			local identifier = viewport._identifier:get()
			scene:flush(identifier)
		end
		self:init(scene, n)
	end,

	resize = function(self)
		--self:init(self.n)
	end,

	project = function(self, x, y)
		local viewport = self.viewports[1]
		return viewport:project(x, y)
	end,

	inputpressed = function(self, ...)
		local controller = self.controller
		controller:inputpressed(...)
	end,

	inputreleased = function(self, ...)
		local controller = self.controller
		controller:inputreleased(...)
	end,

	keypressed = function(self, key, code)
		if key == 'lctrl' then
			self.zooming = true
			self.controller.zooming = true
		end
		if tonumber(key) then
			self:set(tonumber(key))
		end
	end,

	keyreleased = function(self, key, code)
		if key == 'lctrl' then
			self.zooming = false
			self.controller.zooming = false
		end
	end,
}