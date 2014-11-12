function deduplicate(a, f)

	if not a then
		return
	end

	local f = f or function(v, b) return v == b end

	for j,v in pairs(a) do
		for k,b in pairs(a) do
			if f(v, b) and k ~= j then
				table.remove(a, k)
			end
		end
	end

	return a

end