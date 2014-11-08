-- interface for the client and the game
-- saves all turns so that the game can always be rebuilt
-- handles conflicting move resolution

TurnManager = class{
	init = function(self, client, game)

		self.client = client
		self.game = game

	end,

	update = function(self, dt)

	end,

	draw = function(self)

	end,
}