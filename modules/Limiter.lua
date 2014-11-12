Limiter = class{
	init = function(self, values, ruleset)

		local timeout = 0.05
		local timers = {}
		local locked = {}
		for key, value in pairs(values) do
			timers[key] = 0
			locked[key] = true
		end
		self.values = values
		self.ruleset = ruleset
		self.timers = timers
		self.timeout = timeout
		self.locked = locked

	end,

	update = function(self, dt)

		local values = self.values
		local ruleset = self.ruleset
		local timers = self.timers
		local locked = self.locked

		for key, value in pairs(values) do
			if locked[key] then
				local rules = ruleset[key]
				local threshold = rules.threshold
				if threshold then

					local lower = threshold[1]
					local upper = threshold[2]
					local target

					if value < lower then
						target = lower
					elseif value > upper then
						target = upper
					end

					if target then
						local interpolated = value + (target - value) * dt * 5
						self:set(key, interpolated)
					end


				end
			end
		end


	end,

	draw = function(self)

		-- debugging output!
		local values = self.values
		local ruleset = self.ruleset
		local timers = self.timers
		local locked = self.locked

		local status = 'limiter status\n'
		for key, value in pairs(values) do
			local timer = timers[key]
			local s = locked[key] and 'locked' or 'unlocked'
			local append = ('%s (%s) %s\n'):format(key, s, value)
			status = status .. append
		end

		lg.setColor(255, 255, 255)
		lg.print(status, 15, 80)

	end,

	set = function(self, key, input, delta)

		local values = self.values
		local locked = self.locked

		if input then
			-- todo, use the ruleset here to control what these values actually are

			local ruleset = self.ruleset
			local rules = ruleset[key]

			local value = input
			if rules and delta then
				local filter = rules.filter
				if filter then
					value = value + filter(delta)
				end
			end

			-- process value according to input
			if rules then

				local threshold = rules.threshold
				local limit = rules.limit
				if threshold and limit then

					local lower_threshold = threshold[1]
					local upper_threshold = threshold[2]

					local lower_limit = limit[1]
					local upper_limit = limit[2]

					value = math.max(value, lower_limit)
					value = math.min(value, upper_limit)

				end

			end

			if value ~= values[key] then
				values[key] = value
			end

		end

		return values[key]

	end,

	shift = function(self, key, delta)

		if delta then

			local values = self.values
			local value = values[key]

			-- should a filter be set here?

			if value then
				return self:set(key, value, delta)
			end
			
		end

	end,

	unlock = function(self, key)
		local locked = self.locked
		if locked[key] then
			locked[key] = false
		end
	end,

	lock = function(self, key)
		local locked = self.locked
		if not locked[key] then
			locked[key] = true
		end
	end,

	query = function(self, key)
		local values = self.values
		local locked = self.locked
		return values[key], locked[key]
	end,
}