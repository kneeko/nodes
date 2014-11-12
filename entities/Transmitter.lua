-- interface for the client and the game
-- saves all turns so that the game can always be rebuilt
-- handles conflicting move resolution

Transmitter = class{

	init = function(self, client)

		self.client = client
		self.listeners = {}
		self.history = {}

	end,

	register = function(self, key, object)

		if object._listening then
			local listeners = self.listeners
			listeners[key] = object
			object._transmitter = self
		end

	end,

	release = function(self, key)
		local listeners = self.listeners
		listeners[key] = nil
	end,

	broadcast = function(self, message)
	
		--print(message)
		
		-- broadcast message in clientmanager
		-- add to history
	end,

	receive = function(self, message)

		-- these messages will contain queries that need something handle them
		-- i don't think class should actually modify values, nor should the listener
		-- although it will have the history, so technically it should be able to handle desync

	end,

	
	query = function(self)

	end,

}