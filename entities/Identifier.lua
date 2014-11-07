Identifier = class{
	init = function(self)

		-- system uptime
		local timestamp = love.timer.getTime()

		-- create an input for generating a new identifier
		local input = timestamp .. math.random() * 100000

		-- create the id if one wasn't passed on init
		local identifier = identifier or md5(input)

		self.identifier = identifier
		self.timestamp = timestamp

	end,

	set = function(self, identifier)

		local timestamp = love.timer.getTime()

		self.identifier = identifier
		self.timestamp = time

	end,

	get = function(self)
		local identifier = self.identifier
		local timestamp = self.timestamp
		return identifier, timestamp
	end,
}