function combinations(t)

	local pool = {}
	local index = {}

	-- checks if two values have already been paired
	local paired = function(v, b)

		local ib = index[b]
		local iv = index[v]

		if (not ib) or (not iv) then
			return false
		else
			return ib[v] or iv[b]
		end

	end

	local pair = function(v, b)

		index[b] = index[b] or {}
		index[v] = index[v] or {}

		index[b][v] = true
		index[v][b] = true

		local pair = {v, b}

		table.insert(pool, pair)

	end

	for _,v in pairs(t) do
		for _,b in pairs(t) do
			if b ~= v and (not paired(v, b)) then

				pair(v, b)


			end
		end

	end

	return pool

end