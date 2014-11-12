-- this should be an include?
-- how do I make sure it gets updated?
-- how do give includes a value?

Listener = class{

	init = function(self)

		self._cached = {}
		self._listening = {}

		-- let the turn manager know to listen to event broadcasts from this
		-- and to send values to it
		
	end,

	verify = function(self)
		-- check that all the values in the passed table are the same
		-- does that mean we need to remember what they all were the last time?
		local cached = self._cached
		local listening = self._listening
		for _,key in pairs(listening) do
			local value = self[key]
			if cached[key] == nil then
				cached[key] = value
			end
			if cached[key] ~= value then
				self:broadcast(key, value)
			end
		end

	end,

	broadcast = function(self, key, value)
	
		-- tell the turn manager about a value change
		local status = ('[%s, %s] %s: %s -> %s'):format(self._type, self.label, key, self._cached[key], value)

		local cached = self._cached
		cached[key] = value

		local transmitter = self._transmitter
		transmitter:broadcast(status)

		-- we now have a "self._transmitter"
		-- that we can broadcast to
		-- who will then format, timestamp, and send to other users

		-- send self as well?

		-- add this message to the stack of the turn manager
		-- where it will be formatted, timestamped, and given an identifier

	end,

	receive = function(self, key, value)
		-- adjust a value from the manager
	end,

	listen = function(self, ...)
		--self._transmit[key] = self[key]
		local keys = {...}
		for _,key in ipairs(keys) do
			local listening = self._listening
			listening[#listening + 1] = key
		end
		--print('listening for changes in self.' .. key)
	end,

	-- return the difference between a value, table, bool, string
	diff = function(self, cached, value)

	end,

}