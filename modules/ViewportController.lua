-- better name pls
-- captures input in viewport manager
-- and passes anything it doesn't use onwards
-- if there is a drag event active, it would be nice to be able to do viewport shifting with return
-- 
ViewportController = class{
	init = function(self, scene, viewports)
		
		local sensitivity = 1
		local instances = {}
		local decaying = {}

		self.scene = scene
		self.viewports = viewports
		self.target = {0, 0, 0}
		self.interpolated = {0, 0, 0}
		self.instances = instances
		self.sensitivity = sensitivity
		self.decaying = decaying

	end,

	update = function(self, dt)

		-- yum, constants
		local pi = math.pi
		local tau = pi * 2
		local atan2 = math.atan2
		local abs = math.abs
		local sqrt = math.sqrt
		local pow = math.pow
		local sq = function(n) return pow(n, 2) end

		local dx, dy, dz = 0, 0, 0
		local n = 0

		local target = self.target
		local x, y = unpack(target)
		local instances = self.instances

		local migratory = false
		local trails = false
		
		local zooming = false
		local active_inputs = 0
		local deltas = {}

		-- panning and update
		for _,instance in ipairs(instances) do

			-- update the instance counter
			n = n + 1
			
			local active = instance.active
			local id = instance.id
			local source = instance.source
			local position = instance.position
			local follower = instance.follower
			local origin = instance.origin
			local elapsed = instance.elapsed

			instance.elapsed = elapsed + dt

			-- get values from the callback
			local sx, sy = source()
			local px, py = unpack(position)
			local ox, oy = unpack(origin)

			if not active then
				sx, sy = unpack(position)
			end

			local fx, fy = unpack(follower)

			fx = fx + (px - fx) * dt * 14
			fy = fy + (py - fy) * dt * 14

			follower[1] = fx
			follower[2] = fy

			instance.follower = follower

			-- px instead of fx may make things smoother
			local direction = atan2(sy - fy, sx - fx)
			instance.direction = direction or instance.direction

			-- delta for this node
			local sensitivity = self.sensitivity
			local throttle = instance.throttle
			local dampen = sensitivity * throttle

			-- add this input's delta to the frames delta
			local idx = (sx - px)
			local idy = (sy - py)

			deltas[id] = {idx, idy}

			-- add the deltas to the panning motion
			dx = dx - idx * dampen
			dy = dy - idy * dampen

			-- line trace
			instance.poll = math.max(instance.poll - dt, 0)
			if instance.poll == 0 and trails then
				local samples = instance.samples
				samples[#samples + 1] = fx
				samples[#samples + 1] = fy
				instance.poll = instance.rate
			end

			-- if source has changed
			if px ~= sx or py ~= sy then
				local delta = atan2(sy - py, sx - px)
				local trajectory = atan2(oy - sy, ox - sx)
				local difference = abs(delta - trajectory)
				if migratory and difference < threshold then
					-- move the joystick origin towards the source
					origin[1] = origin[1] + (px - sx)
					origin[2] = origin[2] + (py - sy)
				end
			end

			-- update the source position
			instance.position = {sx, sy}

			local active = instance.active
			local decay = instance.decay
			if not active then
				-- instance throttle modulates deltas smoothly
				local duration = instance.duration
				instance.decay = math.min(decay + dt, duration)
				
				local progress = instance.decay / instance.duration
				local throttle = math.abs(progress - 1)
				instance.throttle = throttle

				if progress == 1 then
					table.remove(instances, _)
				end

			else

				instance.decay = math.max(decay - dt, 0)
				local progress = instance.decay / instance.duration
				local throttle = math.abs(progress - 1)
				instance.throttle = throttle
				active_inputs = active_inputs + 1

			end
			
		end

		-- pinch to zoom
		local threshold = pi / 2
		local minimum = 0.12
		local checked = {}

		for i,a in ipairs(instances) do
			for j,b in ipairs(instances) do

				local unique = (a.id ~= b.id) and (not checked[b.id])


				-- touches much have existed for a minimum period
				-- this ensures their directions are accurate
				local eligible = (a.elapsed > minimum) and (b.elapsed > minimum) 
				local is_touch = (tonumber(a.id) and tonumber(b.id))
				local valid = unique and eligible and is_touch
				if valid then

					-- make sure that the touch deltas are non zero
					local ad, bd = deltas[a.id], deltas[b.id]
					if ad and bd then

						-- sometimes ad and bd are nil?... how?
						local adx, ady = unpack(ad)
						local bdx, bdy = unpack(bd)
						local nonzero = adx ~= 0 or ady ~= 0 or bdx ~= 0 or bdy ~= 0

						if nonzero then

							-- check that the touches are moving in opposite directions
							local adir = a.direction % tau
							local bdir = b.direction % tau

							local difference = adir - bdir
							local displacement = abs(difference % tau)
							local opposite = displacement > (threshold) and displacement < (tau - threshold)

							-- we're zooming!
							if opposite then

								-- this will disable panning for this frame
								zooming = true

								-- get viewport size
								local w = lg.getWidth()
								local h = lg.getHeight()
								
								-- get the current position of the touch
								local apx, apy = unpack(a.position)
								local bpx, bpy = unpack(b.position)

								-- get the difference of the current position of the touch pair
								local bx = (apx - adx) - (bpx - bdx)
								local by = (apy - ady) - (bpy - bdy)

								-- get the difference of the previous position of the touch pair
								local ax = apx - bpx
								local ay = apy - bpy

								-- get the squared distance of the current and previous touches
								local before = sq(bx / w) + sq(by / h)
								local after = sq(ax / w) + sq(ay / h)

								-- get the difference between previous and current distances
								-- and then normalize it for using additively 
								-- we could keep this as 1 + delta and use it multiplicatively 
								local direction = sqrt(after / before) - 1

								-- add this touch pairs delta to the frames delta
								dz = dz + direction

							end

						end

					end

				end
			end

			-- add this touch to the checked list so that we
			-- don't get duplicates
			checked[a.id] = true

		end

		-- if zooming, dampen the panning
		local panning = active_inputs > 1 and not zooming
		if panning then
			-- since our deltas are additive we need
			-- to normalize them so that panning remains 1:1
			target[1] = dx * (1 / n)
			target[2] = dy * (1 / n)
		else
			-- ignore if only one finger is pressed
			target[1] = 0
			target[2] = 0
		end

		-- to keep zooming snappy, don't ease its value ever
		target[3] = dz

		-- interpolate to target
		local interpolated = self.interpolated
		local snappiness = 24

		-- ease the panning deltas so that large dts are less jarring
		interpolated[1] = interpolated[1] + (target[1] - interpolated[1]) * dt * snappiness
		interpolated[2] = interpolated[2] + (target[2] - interpolated[2]) * dt * snappiness
		-- zooming doesn't feel very good when eased
		interpolated[3] = target[3]

		-- pass this values into the viewports control limiter
		local scene = self.scene
		local viewports = self.viewports

		local set = function(state, ...)
			local keys = {...}
			for i = 1, #viewports do
				local viewport = viewports[i]
				local limiter = viewport.limiter
				for _, key in ipairs(keys) do
					limiter[state](limiter, key)
				end
			end
		end

		-- locking the limiter
		-- allows it to return to its constraints smoothly
		-- while unlocking it allows control to remain 1:1
		if panning then
			set('unlock', 1, 2)
		else
			set('lock', 1, 2)
		end

		if zooming or self.zooming then
			set('unlock', 3)
		else
			set('lock', 3)
		end

	end,

	draw = function(self)

		if self.debugging then
			lg.setColor(255, 0, 0)
			lg.circle('fill', 30, 30, 10)
			self.debugging = false
		end

		local total = 0
		local status = ''
		local instances = self.instances
		for _,instance in ipairs(instances) do
			local id = instance.id
			status = status .. tostring(id) .. '\n'
			total = total + 1
		end

		lg.setColor(255, 255, 255)
		--lg.print(status, 15, 15)

		local trails = #instances == 1
		local connector = #instances > 1

		for id,instance in ipairs(instances) do

			local px, py = unpack(instance.position)
			local ox, oy = unpack(instance.origin)

			love.graphics.setColor(100, 255, 255)
			love.graphics.line(ox, oy, px, py)

			local elapsed = instance.elapsed

			--love.graphics.setColor(255, 255, 255)
			--love.graphics.print(elapsed, ox, oy)

			love.graphics.setColor(255, 100, 100)
			love.graphics.circle('line', px, py, 14)

			love.graphics.setColor(155, 255, 100)
			love.graphics.circle('line', ox, oy, 14)

			local fx, fy = unpack(instance.follower)

			love.graphics.setColor(155, 255, 255)
			love.graphics.circle('line', fx, fy, 6)

			if instance.direction then

				local amplitude = math.pow(math.pow(fx - px, 2) + math.pow(fy - py, 2), 0.5)
				amplitude = 100
				local dx = math.cos(instance.direction) * amplitude
				local dy = math.sin(instance.direction) * amplitude
				love.graphics.setColor(50, 255, 200)
				love.graphics.line(px, py, px + dx, py + dy)

			end

			if #instance.samples >= 4 then

				love.graphics.setLineWidth(2)
				love.graphics.setColor(255, 155, 255, 155)
				love.graphics.line(instance.samples)
				love.graphics.setLineWidth(1)

			end

		end

		-- what should the target actually do?
		-- if it is panning the viewport, shouldn't it be returning delta x, y, z?
		-- it should only return deltas so that we can retain control over the viewport
		-- for shaking and other events without passing through the controller

		local target = self.target
		local x, y = unpack(target)
		lg.setColor(255, 255, 255)
		--lg.circle('line', lg.getWidth()*0.5 + x, lg.getHeight()*0.5 + y, 15)

		local interpolated = self.interpolated
		local ix, iy, iz = unpack(interpolated)
		lg.setColor(255, 155, 155)
		--lg.circle('line', lg.getWidth()*0.5 + x, lg.getHeight()*0.5 + y, 10)

	end,

	inputpressed = function(self, ...)

		-- filter for valid inputs

		local x, y, id, pressure, source = ...
		local valid = tonumber(id) or id == 'l' or id == 'r'
		local instances = self.instances

		if valid then

			-- check for an existing instance with this
			-- id and take it over if it exists
			local index
			for i,instance in ipairs(instances) do
				if instance.id == id then
					index = i
					break
				end
			end

			local instance = {
				active = true,
				id = id,
				source = source,
				origin = {x, y},
				position = {x, y},
				follower = {x, y},
				samples = {},
				poll = 0,
				rate = 0.025,
				direction = nil,
				throttle = 1,
				decay = 0,
				duration = 0.2,
				elapsed = 0,
			}

			if not index then
				index = #instances + 1
			end

			instances[index] = instance

		end

		-- pass unused events on to scene

		-- conditions:
		--[[
	
		if nothing else is pressed then we can pass this on to scene
	
		what makes the most sense in this case, if it were hard coded
		i should just get the behaviour working and then make it pretty later ;)

		really, if there's no other input we can pass it on
		and the behaviour that nodes have for being activated will take care of the rest

		if we start moving or zooming we want to cancel stuff...
		how can we cancel inputs that

		]]--

		local continue = #instances == 1

		if continue then

			-- maybe pass this onto the object manager? here for each viewport?
			local scene = self.scene
			local viewports = self.viewports
			local x, y, id, pressure, source = ...

			for i = 1, #viewports do

				local viewport = viewports[i]
				local identifier = viewport._identifier:get()
				local camera = viewport.camera

				-- oooh....
				-- so we need to provide a callback with the projection?
				local px, py = camera:project(x, y)
				local project = function()
					local sx, sy, sp = source()
					local cx, cy = camera:project(sx, sy)
					return cx, cy, sp
				end
				scene:inputpressed(identifier, px, py, id, pressure, source, project)

			end

		end

	end,

	inputreleased = function(self, ...)

		local x, y, id, pressure = ...

		-- remove the instance
		-- alas we have to find it
		local instances = self.instances
		for i,instance in ipairs(instances) do
			if instance.id == id then
				--table.remove(instances, i)


				instance.active = false
				-- but after a timer this should end
				--break
			end
		end

		-- pass events on to scene

		-- todo
		-- send relevant locks to the viewport limiter here
		-- that may be simpler if the controller gets these viewports and sends the commands off
		-- since then it can say, viewport.limiter:lock(key) viewport.limiter:unlock(key)

		local scene = self.scene
		local viewports = self.viewports
		local x, y, id, pressure = ...
		for i = 1, #viewports do

			local viewport = viewports[i]
			local identifier = viewport._identifier:get()
			local camera = viewport.camera
			local px, py = camera:project(x, y)

			scene:inputreleased(identifier, px, py, id, pressure)

		end

	end,
}