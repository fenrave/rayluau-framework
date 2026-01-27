---------------------------------------
local Raylib = require("@raylib")
local Camera = Raylib.structs.Camera2D
---------------------------------------
type InternalCamera = setmetatable<{
	read Name: string | number,
	Offset: vector,
	Target: vector,

	Rotation: number,
	Zoom: number,

	Object: Raylib.Camera2D,

	[string]: any
}, {}>

export type Camera = InternalCamera & {
	read Last_Offset: vector,
	read Last_Target: vector,

	read Last_Rotation: number,
	read Last_Zoom: number,
}
---------------------------------------
local ReadList = {

	Offset = function(List: InternalCamera): vector
		return vector.create(
			buffer.readf32(List.Object, 0),
			buffer.readf32(List.Object, 4)
		)
	end,

	Target = function(List: InternalCamera): vector
		return vector.create(
			buffer.readf32(List.Object, 8),
			buffer.readf32(List.Object, 12)
		)
	end,

	Rotation = function(List: InternalCamera): number
		return buffer.readf32(List.Object, 16)
	end,

	Zoom = function(List: InternalCamera): number
		return buffer.readf32(List.Object, 20)
	end,
}
---------------------------------------
local WriteList = {

	Offset = function(List: InternalCamera, Value: vector): ()
		List.Last_Offset = ReadList.Offset(List)
		buffer.writef32(List.Object, 0, Value.x)
		buffer.writef32(List.Object, 4, Value.y)
		
	end,

	Target = function(List: InternalCamera, Value: vector): ()
		List.Last_Target = ReadList.Target(List)
		buffer.writef32(List.Object, 8, Value.x)
		buffer.writef32(List.Object, 12, Value.y)
	end,

	Rotation = function(List: InternalCamera, Value: number): ()
		List.Last_Rotation = ReadList.Rotation(List)
		buffer.writef32(List.Object, 16, Value)
	end,

	Zoom = function(List: InternalCamera, Value: number): ()
		List.Last_Zoom = ReadList.Zoom(List)
		buffer.writef32(List.Object, 20, Value)
	end
}
---------------------------------------
local Meta = {
	__index = function(List, Index: string)
		return ReadList[Index](List)
	end,
	__newindex = function(List, Index: string, Value: vector)
		WriteList[Index](List, Value)
	end
}
---------------------------------------
local function NewCamera(Name, offset: vector, target: vector, rotation: number, zoom: number): Camera
	local InternalStruct: Raylib.Camera2D = Camera:new({
		offset = offset,
		target = target,
		rotation = rotation,
		zoom = zoom
	})

	local returnCamera = setmetatable({
		Object = InternalStruct,
		Last_Offset = offset,
		Last_Target = target,
		Last_Rotation = rotation,
		Last_Zoom = zoom
	},
		Meta
	) :: Camera

	return returnCamera
end

return NewCamera