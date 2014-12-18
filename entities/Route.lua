Route = class{
	init = function(self, series)

		-- series?

		local from, to = unpack(series)

		-- should these be two way?
		-- the directionality is useful, until I want to use this to actually draw
		-- something without overlapping

		self._type = 'route'

		self.position = {0, 0, 0.8}

		self.series = series
		self.from = from
		self.to = to

		-- make the bound contain these objects

		self.overrides = {
			parallax = 1,
			bound = {from, to},
		}
		
		manager:register(self)

	end,
	update = function(self, dt)

	end,

	draw = function(self, ...)

		-- this is a pretty bad way of doing this!
		-- it would be cleaner to pass a token for retrieving this info manually
		local position, _, _, _, _, identifier = ...

		local from = self.from
		local to = self.to

		-- use the series instead...

		-- i need to use the indentifier
		-- i'll need to draw this some other way maybe?
		local fx, fy = unpack(from.projections[identifier])
		local tx, ty = unpack(to.projections[identifier])

		lg.setLineWidth(3)
		lg.setColor(0, 0, 0, 10)
		lg.line(fx, fy + 2, tx, ty + 2)

		lg.setColor(255, 80, 150)
		lg.line(fx, fy, tx, ty)

		local underway = self.underway
		if underway or true then

			local progress = 0.5
			local ux = fx + (tx - fx) * progress
			local uy = fy + (ty - fy) * progress

			lg.setColor(255, 255, 255)
			--lg.print(self._key, ux, uy)

			local s = ''
			for _,node in ipairs(self.series) do
				s = s .. node._key .. ' '
			end

			lg.print(s, ux, uy)

		end

		lg.setLineWidth(1)
	
	end,

	emit = function(self, from, history, source)

		-- todo
		-- figure out why this doesn't generate a new signal
		-- in some cases

		-- consolidate history and source into signal?

		local series = self.series
		local history = history or {}

		local filter = function(series, from, history)
			local destinations = {}
			for _,to in ipairs(series) do

				local valid = to ~= from

				-- todo
				-- make this ruleset inherited from
				-- the node that is being passed through

				--[[
				if valid and #history > 0 then
					if history[1] == to then
						valid = false
					end
				end
				]]--

				if valid then
					for _,location in ipairs(history) do
						if location == to then
							valid = false
							break
						end
					end
				end

				if valid then
					table.insert(destinations, to)
				end

			end
			return destinations
		end

		local destinations = filter(series, from, history) or {}

		local signals = {}
		for index,to in ipairs(destinations) do
			
			local signal = signals[index]
			if not signal then
				signal = Signal()
				table.insert(signals, signal)
			end

			signal.max = from.max or signal.max

			signal.history = {}
			for k,v in ipairs(history) do
				signal.history[k] = v
			end

			local series = {from, to}
			signal:route(series)

		end

		return signals

	end,

	destroy = function(self)
		self:_destroy()
	end,

	sever = function(self, source)

		local series = self.series

		print('severing route with key ' .. self._key .. ' and ' .. #series .. ' connections')

		-- we need to cleanly remove this route from
		-- all members of its series
		for _,member in ipairs(series) do

			if member ~= source then

				-- we need to find the index of this route
				local routes = member.routes
				for i,route in ipairs(routes) do
					if route == self then
						table.remove(routes, i)
					end
				end

			end

		end

		self:_destroy()

	end,

}
