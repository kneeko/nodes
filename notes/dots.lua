
			-- dots for fun
			local j = i - 1
			local w = 10
			local p = 15
			local r = 4
			local column = (j % w)
			local row = math.floor(j / w)
			local x = p + p * column
			local y = p + p * row
			love.graphics.setColor(255, 255, 255, 100)
			love.graphics.circle('line', x, y, r)