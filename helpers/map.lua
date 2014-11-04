function map(fn, t)
	local tb = {}
	for i,v in ipairs(t) do
		tb[i] = fn(i,v)
	end
	return tb
end