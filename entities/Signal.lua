-- connections should be renamed "routes"
-- cats should spawn and interface with these transmission objects along routes
-- and hand them off to other routes
-- maybe a route can "handoff" a tranmission

Signal = class{

	init = function(self)

		self._type = 'signal'

		self.history = {}

		self.scale = {10, 10}
		self.size = {1, 1}
		self.origin = {0.5, 0.5}
		self.position = {0, 0, 0.3}

		self.overrides = {parallax = 1}

		self.distance = 0
		self.max = 10

		self.timer = 0
		self.duration = 2

		manager:register(self)
	end,

	update = function(self, dt)

		-- travel between nodes
		-- when arriving at a node, check in with the route
		-- for next action, otherwise fizzle off with momentum

		-- this is frequently duplicated code
		-- it would be really smart to make a helper for this
		local duration = self.duration
		self.timer = math.min(self.timer + dt, duration)
		if self.timer == duration then

			-- we've arrived!
			-- get a new target from the cat router (lol)

			-- while there is a timer this should pretty much always be defined...
			local to = self.to
			if not to then
				--error(self._key)
			end
			to:grow(10)


			-- find branches
			local branches = {}
			local routes = to.routes
			for _,route in ipairs(routes) do
				
				local history = self.history
				local visited
				for _,location in ipairs(history) do
					if location == route.to then
						visited = true
					end
				end

				if not visited then
					table.insert(branches, route)
				end

			end

			-- debugging
			--[[
			if self._key == 153 and to._key == 20 then
				local err = ''
				for _,route in ipairs(branches[1].series) do
					err = err .. route._key .. '  '
				end
				error(err)
			end
			]]--

			-- emit a signal to those branches
			local distance = self.distance
			local max = self.max
			for _,branch in ipairs(branches) do
				if distance < max then
					-- since we've arrived at the destination
					-- our to is now the starting destination
					-- that should be ignored in the branch
					local from = to
					local history = self.history
					-- maybe pass this signal also?
					local clones = branch:emit(from, history, self)
					for _,clone in ipairs(clones) do
						clone.distance = distance + 1
					end
				end
			end
			
			self:_destroy()

		end


		-- this will eventually be following a smoothed route...
		-- so don't invest too much into making this work right now



		-- set the position here

	end,

	draw = function(self, ...)

		-- this is SO terrible
		local _, _, _, _, _, identifier = ...
		
		local from = self.from
		local to = self.to

		if from and to then

			-- this should be computed in update
			-- i need to use the indentifier
			local fx, fy = unpack(from.projections[identifier])
			local tx, ty = unpack(to.projections[identifier])

			local progress = self.timer / self.duration
			local ux = fx + (tx - fx) * progress
			local uy = fy + (ty - fy) * progress


			local distance = self.distance
			local max = self.max
			local r = 7 - 3 * (distance / max)

			lg.setColor(0, 0, 0, 20)
			lg.circle('fill', ux, uy + 4, r)

			lg.setColor(255, 255, 255, 100)
			lg.circle('fill', ux, uy, r)

			local history = self.history
			local s = '[' .. self._key .. ', ' .. self.distance .. '/' .. self.max .. ']\n'
			local font = lg.getFont()
			local w, h = font:getWidth(tostring(history)), font:getHeight(tostring(history))
			for _,member in ipairs(history) do
				s = s .. member._key .. ' '
			end

			s = s .. '\n' .. tostring(self)

			local lines = 3

			lg.setColor(50, 50, 50)
			lg.rectangle('fill', ux - 2, uy - 2, w + 4, h*lines + 4)

			lg.setColor(255, 255, 255)
			lg.print(s, ux, uy)

		end

	end,

	route = function(self, series)

		local from, to = unpack(series) 
		local history = self.history

		if from and to then

			self.from = from
			self.to = to
			self.timer = 0

			self.overrides.bound = series

			-- add this starting point to the history
			-- so that it can be ignored in future signal branches
			history[#history + 1] = from
			local cap = 3

			if #history > cap then
				table.remove(history, 1)
			end

		end

	end,

}