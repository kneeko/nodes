-- better name pls
-- captures input in viewport manager
-- and passes anything it doesn't use onwards
-- 
Controller = class{
	init = function(self, output)
		
		local sensitivity = 1
		local instances = {}
		local decaying = {}
		local panning = false
		local zooming = false

		self.output = {0, 0, 0}
		self.interpolated = {0, 0, 0}
		self.instances = instances
		self.sensitivity = sensitivity
		self.decaying = decaying
		self.panning = panning
		self.zooming = zooming

	end,

	update = function(self, dt)

		--[[

		so lets say we get all of the deltas

		if individual deltas are over a threshold
		but combined deltas are under a threshold
		we should be zooming

		]]--

		local output = self.output
		local x, y = unpack(output)

		local threshold = math.pi / 4
		local atan2 = math.atan2
		local abs = math.abs

		local dx, dy, dz = 0, 0, 0
		local n = 0

		local output = self.output
		local instances = self.instances

		local migratory = false
		local trails = true


		for _,instance in ipairs(instances) do

			-- really i should get the instance, the source
			-- is the callback for getting more data

			local active = instance.active

			local id = instance.id
			local source = instance.source
			local position = instance.position
			local follower = instance.follower
			local origin = instance.origin

			-- get values from the callback
			local sx, sy = source()
			local px, py = unpack(position)
			local ox, oy = unpack(origin)

			if not active then
				sx, sy = unpack(position)
			end

			-- this should be eased
			-- and nil when there isn't enough movement
			-- we can determine the overall movement using dt
			-- though is may be buggy at low fps


			-- maybe rotate around the source?
			local fx, fy = unpack(follower)

			fx = fx + (px - fx) * dt * 10
			fy = fy + (py - fy) * dt * 10

			--fx = px
			--fy = py

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

			-- use px instead of fx
			dx = dx - (sx - px) * dampen
			dy = dy - (sy - py) * dampen

			instance.poll = math.max(instance.poll - dt, 0)
			if instance.poll == 0 and trails then

				local samples = instance.samples
				samples[#samples + 1] = sx
				samples[#samples + 1] = sy

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

			--[[

			dx = dx + sx - ox
			dy = dy + sy - oy

			]]--
			n = n + 1


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

			end
			
		end


		local pi = math.pi
		local threshold = pi / 2
		local sq = function(n) return math.pow(n, 2) end
		local sqrt = math.sqrt

		local checked = {}
		for i,instance in ipairs(instances) do


			for j,comparison in ipairs(instances) do
				-- make sure we haven't done i already?
				local valid = true
				for _,key in ipairs(checked) do
					if j == key then
						valid = false
					end
				end

				valid = valid and i ~= j

				if valid then


					local displacement = (instance.direction % (pi * 2)) - (comparison.direction % (pi * 2))
					if math.abs(displacement) > threshold then

						-- how much does the scale change by?


						local instance_px, instance_py = unpack(instance.position)
						local instance_fx, instance_fy = unpack(instance.follower)

						local comparison_px, comparison_py = unpack(comparison.position)
						local comparison_fx, comparison_fy = unpack(comparison.follower)

						local position_distance = instance_py - comparison_py
						local follower_distance = instance_fy - comparison_fy

						local position_distance_sq = sq(comparison_px - instance_px) + sq(comparison_py - instance_py)
						local follower_distance_sq = sq(comparison_fx - instance_fx) + sq(comparison_fy - instance_fy)

						local position_distance = sqrt(position_distance_sq)
						local follower_distance = sqrt(follower_distance_sq)
						-- what do I need to reduce this number by for it to be meaningful?
						local delta = (position_distance - follower_distance) * 0.001

						-- this should be much less significant when dx, dy are other a certain threshold
						dz = dz + delta


					end

					checked[#checked + 1] = i

					--dz = (py - fy) * 0.001

					--[[

					what are some ways of doing this?

					if I can get the difference in position from the last frame to the current frame
					what 

					]]--

					--local diff = (instance.direction % math.pi * 2) - (comparison.direction % math.pi * 2)
					
					-- show diff

					-- get previous maybe?

					--if math.abs(diff) > threshold then

						-- how much does the scale change by?
						--dz = diff * dt

					--end

					--[[
					local ifx, ify = unpack(instance.follower)
					local ipx, ipy = unpack(instance.position)
					local cfx, cfy = unpack(comparison.follower)
					local cpx, cpy = unpack(comparison.position)

					local follower_distance = math.pow(ifx - cfx, 2) + math.pow(ify - cfy, 2)
					local position_distance = math.pow(ipx - cpx, 2) + math.pow(ipy - cpy, 2)

					print(position_distance)

					local diff = position_distance - follower_distance
					dz = (diff == diff) and (diff * dt * dt * dt) or 0

					print(diff)
					]]--



				end
			end
		end


		--dx = n > 0 and dx * (1 / n) or 0
		--dy = n > 0 and dy * (1 / n) or 0

		if n > 1 then

			output[1] = dx * (1 / n)
			output[2] = dy * (1 / n)

		else

			output[1] = 0
			output[2] = 0

		end

		output[3] = dz

		-- interpolate output
		local interpolated = self.interpolated
		interpolated[1] = interpolated[1] + (output[1] - interpolated[1]) * dt * 12
		interpolated[2] = interpolated[2] + (output[2] - interpolated[2]) * dt * 12
		interpolated[3] = interpolated[3] + (output[3] - interpolated[3]) * dt * 18

		-- i need to process the zoom delta here
		-- because the zoom should be log based or at least taper off
		-- and certainly be limited to a certain value range

	end,

	draw = function(self)

		local total = 0
		local status = ''
		local instances = self.instances
		for _,instance in ipairs(instances) do
			local id = instance.id
			status = status .. tostring(id) .. '\n'
			total = total + 1
		end

		lg.setColor(255, 255, 255)
		lg.print(status, 15, 15)

		local trails = #instances == 1
		local connector = #instances > 1

		for id,instance in ipairs(instances) do

			local px, py = unpack(instance.position)
			local ox, oy = unpack(instance.origin)

			love.graphics.setColor(100, 255, 255)
			love.graphics.line(ox, oy, px, py)

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

		-- what should the output actually do?
		-- if it is panning the viewport, shouldn't it be returning delta x, y, z?
		-- it should only return deltas so that we can retain control over the viewport
		-- for shaking and other events without passing through the controller

		local output = self.output
		local x, y = unpack(output)
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

		if valid then

			local instances = self.instances

			-- check for an existing instance with this
			-- id and take it over if it exists
			local replace
			for i,instance in ipairs(instances) do
				if instance.id == id then
					replace = i
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
			}

			if not replace then
				replace = #instances + 1
			end

			instances[replace] = instance

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

	end,
}