---------------------------------------
local Pool = require("@Pool")
local Raylib = require("@raylib")
local Rectangle = Raylib.structs.Rectangle
---------------------------------------
type InternalRectangle = setmetatable<{
	read Name: string | number,

	--aliases
	Position: vector,
	Size: vector,
	
	ToPool: (self: Rect, Amount: number?) -> Pool.Pool<Rect>,
	Object: Raylib.Rectangle,
	
	[string]: any
}, {}>

export type Rect = InternalRectangle
---------------------------------------
local ReadList = {
	Position = function(List: InternalRectangle): vector
		return vector.create(
			buffer.readf32(List.Object, 0),
			buffer.readf32(List.Object, 4)
		)
	end,
	Size = function(List: InternalRectangle): vector
		return vector.create(
			buffer.readf32(List.Object, 8),
			buffer.readf32(List.Object, 12)
		)
	end
}

local WriteList = {
	Position = function(List, Value: vector): ()
		buffer.writef32(List.Object, 0, Value.x)
		buffer.writef32(List.Object, 4, Value.y)
	end,

	Size = function(List: InternalRectangle, Value: vector): ()
		buffer.writef32(List.Object, 8, Value.x)
		buffer.writef32(List.Object, 12, Value.y)
	end
}
---------------------------------------
local Meta = {
	__index = function(List: InternalRectangle, Index: string)
		return ReadList[Index](List)
	end,
	__newindex = function(List: InternalRectangle, Index: string, Value: vector)
		WriteList[Index](List, Value)
	end
}
---------------------------------------
local function NewRect(Name, position: vector, size: vector): Rect
	local InternalStruct: Raylib.Rectangle = Rectangle:new({
		x = position.x,
		y = position.y,
		width = size.x,
		height = size.y
	})

	local returnRect = setmetatable({
		Object = InternalStruct
	}, 
		Meta
	) :: Rect

	rawset(returnRect, "ToPool", function(self: Rect, Amount: number?)
		return Pool(
			Name, 
			Rectangle, 
			if not Amount then 1 else Amount, 
			returnRect :: Rect, 
			{
				x = self.Position.x,
				y = self.Position.y,
				width = self.Size.x,
				height = self.Size.y
			}
		)
	end)


	return returnRect
end

return NewRect
