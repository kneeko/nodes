Route = class{
	init = function(self, series)

		-- for now we are going to assume routes travel between two nodes only
		-- even though we could theoretically handle more
		-- i'm not actually sure what that means in this case
		local from, to = unpack(series)

		print('created a route')

		-- should these be two way?
		-- the directionality is useful, until I want to use this to actually draw
		-- something without overlapping

		-- add self to the node routes list
		for _,node in ipairs(series) do
			local routes = node.routes
			table.insert(routes, self)
		end

		self._type = 'route'
		--self._visible = false

		self.position = {0, 0, 0.8}
		self.size = {10, 10}
		self.scale = {1, 1}

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

				if valid then
					for _,location in ipairs(history) do
						if location == to then
							valid = false
						end
					end
				end

				if valid then
					table.insert(destinations, to)
				end

			end
			return destinations
		end

		-- not all nodes in the series are traversable
		-- so use the lamba above to remove them
		local destinations = filter(series, from, history) or {}
		local signals = {}

		for index,to in ipairs(destinations) do
			
			local signal

			-- recycle the source signal
			if source and index == 1 then
				signal = source
			else
				signal = Signal()
			end

			table.insert(signals, signal)

			signal.max = from.max or signal.max

			-- if using seperate histories for each emit
			signal.history = {}
			for k,v in ipairs(history) do
				signal.history[k] = v
			end

			-- override seperate histories
			--signal.history = history

			local series = {from, to}
			signal:route(series)

		end

		return signals

	end,

	destroy = function(self)
		self:_destroy()
	end,

	destroy = function(self, source)

		local series = self.series

		-- we need to cleanly remove this route from
		-- all members of its series
		for _,member in ipairs(series) do
			local routes = member.routes
			for i,route in ipairs(routes) do
				if route == self then
					table.remove(routes, i)
				end
			end
		end

		self:_destroy()

	end,

	contains = function(self, ...)
		local series = self.series
		local seeking = {...}
		local total = #seeking
		local found = {}
		for index,node in ipairs(seeking) do
			for i,entry in ipairs(series) do
				if entry == node then
					table.insert(found, entry)
					table.remove(seeking, index)
					break
				end
			end
		end

		return total == #found

	end,

}
