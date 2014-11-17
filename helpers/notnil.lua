--[[
notnil = function(...)

	for _,v in ipairs({...}) do
		if v == nil then
			return false
		end
	end

	return true
end
]]--