ObjectSorter = class{
	init = function(self, objects)
		self.objects = objects
		self.index = {}
		self.stack = {}
		self.map = {}
	end,

	insert = function(self, key)

		local objects = self.objects
		local index = self.index
		local object = objects[key]
		if object then

			-- set the index
			local x, y, z = unpack(object.position)
			index[key] = {z, y, x}

			-- attempt to find stack insertion point
			local sorted = self.sorted
			local stack = self.stack
			local map = self.map
			local found
			if #stack > 0 then

				-- first test for a layer match
				if map[z] then
					-- sort by y position
					local start, length = unpack(map[z])
					for i = start, start + length - 1 do
						local node = index[stack[i]]
						if node ~= nil then
							local nz, ny, _ = unpack(node)
							if ny >= y then
								found = i
								break
							end
						end
					end
					if not found then
						found = start + length
					end
					map[z][2] = map[z][2] + 1

					-- increment the group value for everything nearer than z
					-- since we don't need to find the specific layers
					for gz, group in pairs(map) do
						if gz < z then
							group[1] = group[1] + 1
						end
					end
				else
					-- the order only matters while traversing if it has not been found
					-- so sort map by z position
					local previous
					local traverse = self.traverse
					local order = function(t,a,b) return b < a end
					for gz, group in traverse(map, order) do
						if gz < z then
							if not found then
								-- the appropriate insertion index has been passed, so make one instead
								if (previous and previous > z) or (not previous) then
									local i = group[1]
									if previous then
										local start, length = unpack(map[previous])
										i = start + length
									end
									found = i
									map[z] = {i, 1}
								end
							end
							-- increment position since everything needs to be displaced
							group[1] = group[1] + 1
						end
						previous = gz
					end
				end
			end

			-- didn't find a place, so it must be nearest object
			if not found then
				found = #stack + 1
				map[z] = {found, 1}
			end

			-- add the key to the stack at the targeted location
			table.insert(stack, found, key)

		end
	end,

	move = function(self, key)
		-- only move if needed
		local objects = self.objects
		local index = self.index
		local object = objects[key]

		-- check that this is a real object

		local x, y, z = unpack(object.position)
		local iz, iy, ip = unpack(index[key])

		-- only proceed with reordering the stack if the object has actually moved
		if z ~= iz or y ~= iy then

			local stack = self.stack
			local map = self.map

			-- find the key position from the stack map
			local start, length = unpack(map[iz])
			local found
			for i = start, start + length - 1 do
				local node = stack[i]
				if node == key then
					found = i
					break
				end
			end

			if not found then
				print('dumping drawstack:')
				print(unpack(stack))
				local err = 'unable to find ' .. key .. ' in map for ' .. iz .. '(' .. start .. ' -> ' .. start + length - 1 .. ')'
				error(err)
			end

			-- compare to neighbors in stack
			-- if the object has not changed enough to pass them
			-- then we only need to update its index and map
			local shuffle
			local neighbors = {
				{i = found - 1, f = function(a, b) return a < b end},
				{i = found + 1, f = function(a, b) return a > b end},
			}
			for i = 1, #neighbors do
				local neighbor = neighbors[i]
				local node = index[neighbor.i]
				if node then
					local nz, ny, nx = unpack(node)
					if neighbor.f(nz, z) then
						shuffle = true
						break
					elseif nz == z then
						if neighbor.f(ny, y) then
							shuffle = true
							break
						end
					end
				end
			end

			-- override partial shuffles until I can resolve the indices being incorrectly shifted
			shuffle = true

			-- the object has moved enough to need to change the draw order
			-- so remove and reinsert to correct the index, map, and stack
			-- this incurs a little bit of overhead due to the table creation
			if shuffle then
				self:remove(key)
				self:insert(key)
			else
				-- save the new object position
				index[key] = {z, y, x}

				-- update the current map length
				if map[z] then
					map[z][2] = map[z][2] + 1
				else
					-- create a new one if it doesn't exist
					map[z] = {map[iz][1], 1}
				end

				-- update the previous map length
				if map[iz][2] == 1 then
					-- remove the map if this was the last object at that depth
					map[iz] = nil
				else
					map[iz][2] = map[iz][2] - 1
				end

			end
		end

	end,

	remove = function(self, key)

		local objects = self.objects
		local index = self.index
		local z, y, p = unpack(index[key])
		index[key] = nil

		-- find and remove the key from the drawstack
		local sorted = self.sorted
		local stack = self.stack
		local map = self.map
		local group = map[z]
		local start, length = unpack(group)

		local index
		for i = start, start + length - 1 do
			if stack[i] == key then
				index = i
				break
			end
		end

		if index then

			-- native table removal moves all other elements down
			-- this should be ok for around a hundred elements
			table.remove(stack, index)

			group[2] = group[2] - 1
			if group[2] == 0 then
				map[z] = nil
			end

			-- offset the start position of the groups effected by the removal
			for gz, group in pairs(map) do
				if gz < z then
					group[1] = group[1] - 1
				end
			end

		end

	end,

	traverse = function(t, order)
		local keys = {}
		for k in pairs(t) do keys[#keys + 1] = k end
		-- if order function given, sort by it by passing the table and keys a, b,
		-- otherwise just sort the keys 
		if order then
			table.sort(keys, function(a,b) return order(t, a, b) end)
		else
			table.sort(keys)
		end
		-- return the iterator function
		local i = 0
		return function()
			i = i + 1
			if keys[i] then
				return keys[i], t[keys[i]]
			end
		end
	end,
}