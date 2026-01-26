local System = require("@System")

local Render = System.Render
local Camera = System.Camera

local Rect = System.Rect
--------------------------------
local Quail = System.Utils.Quail

local Const = System.rConsts
local Lib = System.rLib
local Structs = System.rStructs
local rand = zune.random.new()
local Args = zune.process.args
local ffi = zune.ffi
local buf = ffi.struct({
	{len = ffi.types.double}
})

local API = ffi.c.compile([[
typedef struct Rectangle {
    float x;
    float y;
    float width;
    float height;
} Rectangle;

void* main(void* buffer) {
	return buffer;
}

]])

local CastPtr = ffi.fn(
	{returns = ffi.types.u64, args = {ffi.types.pointer}},
	API:getSymbol("main") :: FFIPointer
) :: (FFIPointer) -> (buffer)

local Nest = Quail:NewNest(3)

Nest:AddModule({collide = "../../../../src/internals/libraries/threads/lib_Threads/collide"})

local b = Nest:InitBevy("Static")

local function Main(Args: {string}): ()
	local NewCam = Camera("Test", vector.create(0,0), vector.create(0,0), 0, 1)
	
	local RectPool = Rect(
		"Test", 
		vector.create(
			425, 
			325
		), 
		vector.create(
			25,
			25
		)
	):ToPool(200):Populate()
	local pos = vector.create(425, 325)

	b[pos] = {}

	RectPool:Iterate(function(Object, Index: number)
		Object.Position += vector.create(rand:nextInteger(-200, 200), rand:nextInteger(-200, 200))
		table.insert(b[pos], {
			Object = Object.Object,
			Position = Object.Position,
			Size = Object.Size
		})
	end)

	b:Sync()

	local hi = RectPool:TagGroup("Hi"):AddTag("h", 1)
	
	local TestRect = Rect("Test2", vector.create(400, 300), vector.create(25, 25)):ToPool(10):Populate()

	local ToSend: {buffer} = {}

	TestRect:Iterate(function(Object, Index: number)
		Object.Position += vector.create(rand:nextInteger(-250, 250), rand:nextInteger(-250, 250))

		local ptr = zune.ffi.alloc(Structs.Rectangle:size(), Structs.Rectangle:alignment())
		-- local ptr = Lib.MemAlloc(16)


		ptr:write(0, Object.Object, 0, 16)

		table.insert(
			ToSend,
			CastPtr(ptr)
		)
	end)

	local qh = Nest:AssignJob({
		ModuleName = "collide",
		Data = ToSend,
		Limit = 1
	})

	qh:OnComplete(function(...)
		
	end)

	Lib.SetConfigFlags(Const.ConfigFlags.FLAG_WINDOW_MAXIMIZED)
	Lib.SetConfigFlags(Const.ConfigFlags.FLAG_WINDOW_RESIZABLE)
	Lib.InitWindow(825, 625, "Test")
	Lib.SetTargetFPS(60)
	Render:SetCamera(NewCam.Object)

	local positions = {}

	Render:AddToQueue("PreRender", "Test", function()
		TestRect:Iterate(function(Object, Index: number)
			zune.io.stderr:lock("none")
			Object.Position = vector.lerp(Object.Position, pos, .003)
			zune.io.stderr:unlock()
		end)
	end)

	Render:AddToQueue("Render", "Test", function()
		RectPool:Iterate(function(Object: System.Rectangle)
			Lib.DrawRectangleRec(Object.Object, Const.GOLD)
		end)
		
		TestRect:Iterate(function(Object, Index: number)
			zune.io.stderr:lock("none")

			Lib.DrawRectangleRec(Object.Object, Const.BEIGE)
			zune.io.stderr:unlock()
		end)
	end)

	local RenderCode = Render:StartRender(); do
		Lib.CloseWindow()
		zune.process.exit(RenderCode)
	end

end; Main(Args)
