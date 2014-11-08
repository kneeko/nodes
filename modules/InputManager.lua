InputManager = class{
	init = function(self)
		-- detect touch, get scaling sizes
		self.destinations = {}
		self.profiles = {}
		self.map = {}
		self.sources = {}

		local width = lg.getWidth()
		local height = lg.getHeight()

		self.width = width
		self.height = height



	end,

	-- add or modify this input destination profile
	register = function(self, destination, callbacks)

		local destinations = self.destinations
		local profiles = self.profiles
		local map = self.map

		-- todo
		-- blacklist regions or keys
		-- whitelist regions or keys

		local callbacks = callbacks or {}
		local profile = {
			destination = destination,
			callbacks = callbacks,
		}

		-- replace the existing profile if it exists
		for profile, i in pairs(map) do
			if profile == destination then
				self:release(destination)
				self:register(destination, callbacks)
				return
			end
		end

		-- otherwise add a new one
		local index = #destinations + 1 
		destinations[index] = profile
		map[destination] = index

		-- put the index into 
		for _, callback in ipairs(callbacks) do
			local pool = profiles[callback] or {}
			-- go through the pool and make sure we are not already here
			pool[#pool + 1] = index
			profiles[callback] = pool
		end

		local status = ('InputManager registered "%s" with %s callback types: %s' ):format(tostring(destination._type), #callbacks, table.concat(callbacks, ', '))
		--print(status)

		return

	end,

	release = function(self, destination)

		local destinations = self.destinations
		local map = self.map
		local profiles = self.profiles
		for profile, index in pairs(map) do
			if profile == destination then

				-- remove any instances of the profile key in the callback pools
				for _, callback_type in pairs(profiles) do
					for i, key in ipairs(callback_type) do
						if key == index then
							table.remove(callback_type, i)
							break
						end
					end
				end

				destinations[index] = nil
				map[profile] = nil

				local status = ('Removing "%s" from InputManager.'):format(tostring(destination._type))
				--print(status)

				return
			end
		end

	end,

	update = function(self, dt)
	end,

	mousepressed = function(self, x, y, button)

		local id = button
		local pressure = 1

		self:add_source(id, 'mouse')
		local source, active = self:get_source(id)

		self:dispatch('inputpressed', 'input', x, y, id, pressure, source)

	end,

	mousereleased = function(self, x, y, button)

		local id = button
		local pressure = 1

		self:dispatch('inputreleased', 'input', x, y, id, pressure)
		self:rem_source(id)

	end,

	touchpressed = function(self, id, x, y, pressure)

		local x, y = self:to_screen(x, y)

		self:add_source(id, 'touch')
		local source, active = self:get_source(id)

		self:dispatch('inputpressed', 'input', x, y, id, pressure, source)

	end,

	touchreleased = function(self, id, x, y, pressure)

		local x, y = self:to_screen(x, y)

		self:dispatch('inputreleased', 'input', x, y, id, pressure)
		self:rem_source(id)

	end,

	keypressed = function(self, key, code)
		self:dispatch('keypressed', 'keyboard', key, code)
	end,

	keyreleased = function(self, key, code)
		self:dispatch('keyreleased', 'keyboard', key, code)
	end,

	dispatch = function(self, callback, method, ...)
		
		local destinations = self.destinations
		local profiles = self.profiles
		local indices = profiles[method]
		local types = self.types

		for _,index in ipairs(indices) do
			local profile = destinations[index]
			local destination = profile.destination
			if destination[callback] then
				destination[callback](destination, ...)
			end
		end

	end,

	to_screen = function(self, x, y)

		local w, h = self.width, self.height
		return x * w, y * h

	end,

	add_source = function(self, id, method)

		local sources = self.sources
		local source

		if method == 'touch' then

			source = function()
				local touch = love.touch
				local c = touch.getTouchCount()
				for n = 1, c do
					local tid, tx, ty, pressure = touch.getTouch(n)
					if tid == id then
						local x, y = self:to_screen(tx, ty)
						local active = true
						return x, y, pressure, active
					end
				end
			end

		elseif method == 'mouse' then

			source = function()
				local x, y = love.mouse.getPosition()
				local active = love.mouse.isDown(id)
				local pressure = 1
				return x, y, pressure, active
			end

		end

		sources[id] = source

	end,

	rem_source = function(self, id, method)

		local sources = self.sources
		sources[id] = nil

	end,

	get_source = function(self, id)

		local sources = self.sources
		local source = sources[id]

		return source

	end,

}