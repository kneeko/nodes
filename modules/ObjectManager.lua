ObjectManager = class{
	init = function(self)

		local available = {}
		local objects = {}
		local sorter = ObjectSorter(objects)
		local renderer = ObjectRenderer(objects, sorter)
		local context = (os.time()) .. '-' .. math.floor(math.random() * 1000)

		self.available = available
		self.objects = objects
		self.sorter = sorter
		self.renderer = renderer
		self.context = context
		self.index = {}

		print('ObjectManager init\'d with context ' .. context)

	end,

	update = function(self, dt)

		-- should I be doing the projection here?
		-- well, I only want to be projecting objects
		-- that are returned by the sorter, so perhaps not..
		local objects = self.objects
		local sorter = self.sorter
		local heap = self:get()
		for i = 1, #heap do
			local key = heap[i]
			local object = objects[key]
			if object.active then
				object:update(dt)
				object:compute()
				
				-- do I need to call this every frame?
				sorter:move(key)
			end
		end

		--renderer:prepare(camera, viewport)

	end,

	draw = function(self, camera, viewport)
	
		local renderer = self.renderer
		renderer:draw(camera, viewport)

		-- draw the viewport bound in worldspace
		local x, y, z = unpack(camera)
		local l, r, t, b = unpack(viewport)
		lg.setColor(255, 255, 255, 100)
		lg.rectangle('line', x - 1, y - 1, r - l + 2, b - t + 2)

	end,

	callback = function(self, method, ...)

		local index = self.index
		local objects = self.objects
		local keys = index[method]
		if keys then
			for _,key in ipairs(keys) do
				local object = objects[key]
				object[method](object, ...)
			end
		end

	end,

	register = function(self, object)

		local objects = self.objects
		local sorter = self.sorter
		local available = self.available
		local heap = self:get() or {}
		local context = self.context

		local key
		for i,suggestion in ipairs(available) do
			local suggestion = available[i]
			table.remove(available, i)
			local n = heap[#heap]
			if n then
				if suggestion < heap[#heap] then
					key = suggestion
					break
				end
			end
		end

		-- if there was nothing available then just add a new key
		key = key or #objects + 1

		-- store the main reference to the object
		objects[key] = object

		-- copy fallback values from entity
		object:include(Entity:init(key, context))
		object:include(Entity)

		-- include any requested classes
		local includes = object.includes or {}
		for _,include in ipairs(includes) do
			object:include(include:init())
			object:include(include)
		end

		-- index any requested callbacks
		local index = self.index
		local callbacks = object.callbacks or {}
		for _,callback in ipairs(callbacks) do
			index[callback] = index[callback] or {}
			index[callback][#index[callback] + 1] = key
		end

		sorter:insert(key)

		return key
	end,

	release = function(self, key)

		local objects = self.objects
		local available = self.available
		local sorter = self.sorter
		local index = self.index
		local heap = self:get()
		local object = objects[key]
		if type(object) == 'table' then
			local callbacks = object.callbacks or {}
			for _,callback in ipairs(callbacks) do
				local keys = index[callback] or {}
				for i,v in ipairs(keys) do
					if v == key then
						table.remove(keys, i)
					end 
				end
			end
			sorter:remove(key)
			available[#available + 1] = key
			objects[key] = nil
		end
		
	end,

	pop = function(self)
		local objects = self.objects
		local heap = self:get()
		local i = math.ceil(#heap * math.random())
		local key = heap[i]
		if key then
			self:release(key)
		end
	end,

	get = function(self)
		local objects = self.objects
		local heap = {}
		for key,object in pairs(objects) do
			heap[#heap + 1] = key
		end
		return heap
	end,

	delegate = function(self, method, ...)
		local objects = self.objects
		local index = self.index
		if index[method] then
			for _,key in ipairs(index[method]) do
				objects[key][method](objects[key], ...)
			end
		end
	end,

	mousepressed = function(self, ...)
		local x, y, button = ...
		-- how do I keep this viewport agnostic?
		self:delegate('mousepressed', x, y, button)
	end,

}