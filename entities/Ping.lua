-- traverse along a terminal's path...


-- in order to account for curvy paths this will always read its current path and the connection
-- ahead of that one
-- which will force it to deal with seperation prior to actually hitting a junction

-- since we will be traveling along connected nodes which all have neighbors


Ping = class{

	init = function(self)

		self._type = 'ping'

		self.scale = {10, 10}
		self.size = {1, 1}
		self.origin = {0.5, 0.5}
		self.position = {0, 0, 0.6}

		self.overrides = {parallax = 1}
		self.positioning = 'relative'

		self.history = {}

		self.timer = 0
		self.duration = 0.1

		manager:register(self)

	end,

	update = function(self, dt)
		local timer = self.timer
		local duration = self.duration
		self.timer = math.min(timer + dt, duration)
		if self.timer == duration then
			self:depart()
		end

		local velocity = self.velocity or {0, 0}
		local vx, vy = unpack(velocity)

		local position = self.position
		local x, y = unpack(position)

		position[1] = x + vx * dt
		position[2] = y + vy * dt

	end,

	draw = function(self, identifier, ...)
		local projection = ...
		local x, y = unpack(projection)
		lg.setColor(255, 255, 255, 100)
		lg.circle('fill', x, y, 16)

		local history = self.history
		local s = ''
		for _,visited in ipairs(history) do
			s = s .. visited._key .. '\n'
		end

		lg.setColor(255, 255, 255)
		--lg.print(s, x + 30, y)

		local visiting = self.visiting
		local exists = manager.objects[visiting._key] ~= nil
		--lg.print(tostring(exists), x + 10, y + 10)
		

	end,

	-- start a ping here
	visit = function(self, node)
		if node then

			print('signal is visiting node ' .. node._key)

			self.visiting = node
			self.parent = node
			self.timer = 0

			local history = self.history
			history[#history + 1] = node

		end
	end,

	depart = function(self)
		-- go visit the neighbors of this node
		-- this may result in branching
		-- or destroying this signal

		local history = self.history
		local visiting = self.visiting

		local branched = {}
		local branches = visiting.neighbors or {}
		for _,branch in ipairs(branches) do

			local skipping
			for _,visited in ipairs(history) do
				if branch == visited then
					skipping = true
				end
			end

			-- if not branched, not in history etc
			if not skipping then

				if #branched > 0 then
					-- we need to make a new node with the same history
					local replica = Ping()

					-- write a debug message
					local debug = Message()
					debug.parent = branch
					debug.string = 'branched to ' .. branch._key .. ' from ' .. visiting._key

					-- now, unfortunately this will cause the replica's history to include
					-- the branch being visited by the primary signal
					-- which we may not want

					local replica_history = {}
					for _,visited in ipairs(history) do
						local excluding
						for _,node in ipairs(branched) do
							if node == visited then
								excluding = true
							end
						end
						-- if visited is a branch
						-- we probably want to exclude it?
						if not excluding then
							table.insert(replica_history, visited)
						end
					end
					replica.history = replica_history

					-- we have to visit the branch after fixing the history in order to include it
					replica:visit(branch)
				else
					self:visit(branch)
				end


				table.insert(branched, branch)

			end
		end

		if #branched == 0 then

			self:fire()			
			--self:destroy()

		end

	end,

	destroy = function(self)
		self:_destroy()
	end,

	fire = function(self)
		if not self.velocity then
			local history = self.history
			local previous = history[#history - 1]
			local visiting = self.visiting
			if previous then
				local vx, vy = unpack(visiting.parent.position)
				local px, py = unpack(previous.parent.position)

				local dx = vx - px
				local dy = vy - py
				
				local velocity = {dx * 3, dy * 3}
				print(dx, dy)
				self.velocity = velocity
			end

		end
	end,

}