local callback = function(dir, global, file)
	local filename = string.gsub(file, '.lua', '')
	local path = dir .. '/' .. filename
	if global then
		_G[filename] = require(path)
	else
		require(path)
	end
end

local sets = {
	{
		dir = 'lib',
		global = true,
		callback = callback,
	},
	{
		dir = 'net',
		callback = callback,
	},
	{
		dir = 'modules',
		callback = callback,
	},
	{
		dir = 'entities',
		callback = callback,
	},
	{
		dir = 'helpers',
		callback = callback,
	},
}

return function()
	for _,set in ipairs(sets) do
		love.filesystem.getDirectoryItems(set.dir, function(...) set.callback(set.dir, set.global, ...) end)
	end
	if aliases then
		aliases()
	end
end