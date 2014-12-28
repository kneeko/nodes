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

		self.capped = false
		self.cap = 8

		-- todo
		-- dont use absolute timing to move the signal through a route
		-- use the distance instead
		-- bear in mind that the distance could be changing

		self.timer = 0
		self.duration = 0.35

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

			to:grow(1)


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
			local capped = self.capped
			local cap = self.cap

			local count = 0
			local carryover = self
			local replicas = {}

			for _,branch in ipairs(branches) do
				if (distance < cap) or (not capped) then

					-- since we've arrived at the destination
					-- our to is now the starting destination
					-- that should be ignored in the branch
					local from = to
					local history = self.history
					-- maybe pass this signal also?
					replicas = branch:emit(from, history, carryover)

					-- only reuse self once
					if #replicas > 0 then
						carryover = nil
					end

					for _,replica in ipairs(replicas) do
						replica.distance = distance + 1
					end

				end
			end
			
			-- if nothing used the carryover then we should
			-- destroy this signal
			if carryover then
				self:_destroy()
			end

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
			local max = self.cap
			local r = 8 - 3 * (distance / max)

			lg.setColor(0, 0, 0, 20)
			lg.circle('fill', ux, uy + 4, r, 32)

			lg.setColor(255, 255, 255, 160, 32)
			lg.circle('fill', ux, uy, r)

			lg.setColor(255, 255, 255, 100)
			--lg.circle('line', ux, uy, r * 1.5, 32)

			local history = self.history
			local s = '[' .. self._key .. ', ' .. self.distance .. '/' .. self.cap .. ']'
			local font = lg.getFont()
			local w, h = font:getWidth(tostring(history)), font:getHeight(tostring(history))
			for _,member in ipairs(history) do
				--s = s .. member._key .. ' '
			end

			s = s .. '\n' .. tostring(self)

			local lines = 2

			lg.setColor(50, 50, 50, 100)
			--lg.rectangle('fill', ux - 2, uy - 2, w + 4, h*lines + 4)

			lg.setColor(255, 255, 255, 200)
			--lg.print(s, ux, uy)

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

			-- we should avoid going along a sequence of nodes that we've been to before
			-- rather than just the node itself
			local cap = 5
			local capped = self.capped

			if capped and #history > cap then
				table.remove(history, 1)
			end

		end

	end,

}