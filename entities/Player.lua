-- interface for human, network, and ai controller drivers to manipulate gamestate
Player = class{
	init = function(self)

		self._type = 'player'

		-- i should have a function for this
		local identifier = Identifier()
		self._identifier = identifier

		getManager():register(self)
	end,

	update = function(self)
	end,

	draw = function(self, ...)
	end,	
}