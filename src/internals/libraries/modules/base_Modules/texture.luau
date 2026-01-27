---------------------------------------
local Raylib = require("@Raylib")
local Texture = Raylib.structs.Texture2D
local TextureLoader = Raylib.lib.LoadTexture
---------------------------------------
type InternalTexture = {
	Rect: buffer?,
	read Texture: buffer,

	read ID: number,
	Size: vector,
	Mipmaps: number,
	Format: number
}

type Texture = setmetatable<InternalTexture | {}, {}>
---------------------------------------
type Loader = (FilePath: buffer & string, Rectangle: buffer?) -> Texture
---------------------------------------

local Readers = {
	Size = function(Texture: buffer)
		return vector.create(
			buffer.readi32(Texture, 4),
			buffer.readf32(Texture, 8)
		)
	end,
	Mipmaps = function(Texture: buffer)
		return buffer.readi32(Texture, 12)
	end,
	Format = function(Texture: buffer)
		return buffer.readi32(Texture, 16)
	end
}

local Writers = {
	Size = function(Texture: buffer, Value: vector)	
		buffer.writei32(Texture, 4, Value.x)
		buffer.writei32(Texture, 8, Value.y)
	end,
	Mipmaps = function(Texture: buffer, Value: number)
		buffer.writei32(Texture, 12, Value)
	end,
	Format = function(Texture: buffer, Value: number)
		buffer.writei32(Texture, 16, Value)
	end
}

local function Reader(Tex: InternalTexture, Index: string)
	return Readers[Index](Tex.Texture)
end

local function Writer(Tex: InternalTexture, Index: string, Value: number)
	return Writers[Index](Tex.Texture)
end

local function Loader(FilePath: buffer & string, Rectangle: buffer?): Texture
	local LoadedTexture = TextureLoader(FilePath)

	if not LoadedTexture then
		error(`'{FilePath}' Failed to load`)
	end

	local NewTexture: Texture = setmetatable({
		Rect = Rectangle,
		ID = buffer.readu32(LoadedTexture, 0),
		Texture = LoadedTexture
	}, {
		__index = Reader,
		__newindex = Writer
	})

	return NewTexture
end

return Loader :: Loader