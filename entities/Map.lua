Map = class{
	init = function(self, nodes, tiles)

		-- contains a mesh that draws the tiles
		-- this allows for textures and coloring...

		-- a tile will call refresh on its tilemap
		-- which will modify its vertices

		-- the list of nodes in a graph are actually what contain unique vertices
		-- but the tiles want to be in control of it... hmm...
		-- and will I be able to do strips of it or not?
		-- err....

		-- a node can know its vertex position in the tilemap
		-- but if tiles share vertices then im not sure i'll be able to do any
		-- partial-triangle specific effects...

		-- oh, I should use triangle list lol
		-- that is much much easier

		-- if i want to set a vertex, I can set it on here but a tile will do so through this
		-- 

		self.tiles = tiles
		for _,tile in ipairs(tiles) do
			tile._map = self
		end

		self.index = {}
		self.vertices = {}

		-- i probably want to make sure this gets updated last
		-- should I have a flag for that?

		-- maybe this should just be updated and drawn by the graph, not a seperate thing...?
		-- does that make sense? it isn't really a game object
		-- getManager():register(self)

	end,

	update = function(self)
	end,

	draw = function(self)
	end,

	-- set a vertex
	set = function(self, tile, vertices)

		-- lookup the vertex in index
		-- and set it...
		-- can we set all vertices at once?

		local index = self.index
		local locations = index[tile._key]

		if locations then
			local v1, v2, v3 = unpack(locations)
		else
			-- we need to add these in the right spot, err....
		end


		-- how hard will adding types be...?



	end,


}