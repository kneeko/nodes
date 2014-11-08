ViewportManager = class{
	init = function(self, scene, n)

		self.scene = scene

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

		local controller = Controller()
		self.controller = controller

	end,

	update = function(self, dt)

		local controller = self.controller
		controller:update(dt)

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

		local controller = self.controller
		local cx, cy, cz = unpack(controller.interpolated)

		-- should the viewport have a limiter built in?
		-- that makes sense I guess


		local viewports = self.viewports
		local scene = self.scene
		for i = 1, #viewports do
			local viewport = viewports[i]
			-- TODO fix the angled translation
			viewport:rotate(dr)
			local angle = viewport.angle
			local x = cx--dx-- * math.cos(angle) + dy * math.sin(angle)
			local y = cy--dy-- * math.sin(angle) + dy * math.cos(angle)
			local z = cz + dz
			viewport:translate(x, y, z)
			viewport:update(dt)
			viewport:prepare(scene)
		end
	end,

	draw = function(self)


		local scene = self.scene
		local viewports = self.viewports
		for i = 1, #viewports do
			viewports[i]:draw(scene)
		end

		local controller = self.controller
		controller:draw()

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

		-- we shouldn't pass any input to the scene until
		-- we know that the controller doesn't mind
		-- kthanx

		-- maybe pass this onto the object manager? here for each viewport?
		local scene = self.scene
		local viewports = self.viewports
		local x, y, id, pressure, source = ...

		for i = 1, #viewports do

			local viewport = viewports[i]
			local identifier = viewport._identifier:get()
			local camera = viewport.camera
			local px, py = camera:project(x, y)

			-- todo, reference the id to decide what this should return
			-- todo, handle this part in the input manager

			scene:inputpressed(identifier, px, py, id, source)
		end

	end,

	inputreleased = function(self, ...)

		local controller = self.controller
		controller:inputreleased(...)

		-- maybe pass this onto the object manager? here for each viewport?
		local scene = self.scene
		local viewports = self.viewports
		local x, y, id, pressure = ...

		for i = 1, #viewports do

			local viewport = viewports[i]
			local identifier = viewport._identifier:get()
			local camera = viewport.camera
			local px, py = camera:project(x, y)

			-- todo, reference the id to decide what this should return
			-- todo, handle this part in the input manager

			scene:inputreleased(identifier, px, py, id, pressure)
		end
	end,

	keypressed = function(self, key, code)
		if key == ' ' then
			self.panning = true
		end
		if key == 'lctrl' then
			self.zooming = true
		end
		if key == 'lshift' then
			--self.rotating = true
		end

		if tonumber(key) then
			self:set(tonumber(key))
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
			--self.rotating = false
		end
	end,
}