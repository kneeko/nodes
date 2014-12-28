function love.conf(t)
	
	io.stdout:setvbuf("no")
	--t.console = true
	--require('cupid')
	t.window.vsync = true
	t.window.highdpi = true
	t.window.vsync = true
	t.window.fsaa = 0
	t.window.srgb = false

	-- iphone
	--t.window.width = 667
	--t.window.height = 375

end
