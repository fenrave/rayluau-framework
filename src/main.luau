---------------------------------------
local System = require("@System")
local Render = System.Render
local Camera = System.Camera
local Rect = System.Rect
local Quail = System.Utils.Quail
local Input = System.Input
local Entity = System.Entity
---------------------------------------
local Const = System.rConsts
local Lib = System.rLib
local Structs = System.rStructs
---------------------------------------
local rand = zune.random.new()
local Args = zune.process.args
local ffi = zune.ffi
---------------------------------------
local API = ffi.c.compile([[
	void* main(void* buffer) {
		return buffer;
	}
]])

local CastPtr = ffi.fn(
	{returns = ffi.types.i64, args = {ffi.types.pointer}},
	API:getSymbol("main") :: FFIPointer
) :: (FFIPointer) -> (buffer)
---------------------------------------
local function Main(Args: {string}): ()
	local NewCam = Camera("Test", vector.create(0,0), vector.create(0,0), 0, 1)
	
	local MainRect = Entity(Rect("Player", vector.zero, vector.create(20, 20)))

	local RectPool = Rect(
		"Test", 
		vector.create(
			425, 
			325
		), 
		vector.create(
			math.random(10, 20),
			math.random(10, 20)
		)
	):ToPool(200):Populate()
	local pos = vector.create(425, 325)
	_G.StaticObjects[pos] = {}
	local step = vector.create(0, 0)
	local iter = 0
	
	RectPool:Iterate(function(Object, Index: number)
		Object.Position += step + vector.create(rand:nextInteger(-200, 200), rand:nextInteger(-200, 200))

		if not _G.StaticObjects[step] then
			_G.StaticObjects[step] = {}
		end
		
		table.insert(_G.StaticObjects[step], {
			Object = Object.Object,
			Position = Object.Position,
			Size = Object.Size/2
		})

		if iter >= 20 then
			step = vector.create(rand:nextInteger(-400, 400), rand:nextInteger(-400, 400))
			iter = 0
		end; iter +=1

	end)

	local hi = RectPool:TagGroup("Hi"):AddTag("h", 1)
	
	local TestRect = Rect("Test2", vector.create(400, 300), vector.create(10, 10)):ToPool(100):Populate()

	Input:RegisterKey("W"):OnDown(function(DT: number)
		MainRect.Direction += vector.create(0,-1)
	end)

	Input:RegisterKey("A"):OnDown(function(DT: number)
		MainRect.Direction += vector.create(-1,0)
	end)

	Input:RegisterKey("S"):OnDown(function(DT: number)
		MainRect.Direction += vector.create(0,1)
	end)

	Input:RegisterKey("D"):OnDown(function(DT: number)
		MainRect.Direction += vector.create(1,0)
	end)


	TestRect:Iterate(function(Object, Index: number)
		Object.Position += vector.create(rand:nextInteger(-500, 500), rand:nextInteger(-500, 500))
		System.Collisions(Object.Object)
	end)
	
	Lib.SetConfigFlags(Const.ConfigFlags.FLAG_WINDOW_MAXIMIZED)
	Lib.SetConfigFlags(Const.ConfigFlags.FLAG_WINDOW_RESIZABLE)
	Lib.InitWindow(825, 625, "Test")
	Lib.SetTargetFPS(120)
	Render:SetCamera(NewCam.Object)
	NewCam.Offset = pos
	local positions = {}

	System.Collisions(MainRect.Rectangle.Object)

	Render:AddToQueue("PreRender", "Test", function()
		NewCam.Offset = vector.create(Lib.GetScreenWidth(), Lib.GetScreenHeight())/2
		NewCam.Target = MainRect.Position + MainRect.Velocity
		TestRect:Iterate(function(Object, Index: number)
			Object.Position = vector.lerp(Object.Position, pos, .005)

			if vector.magnitude(Object.Position - pos) < 50 then
				Object.Position = pos + vector.create(rand:nextInteger(-600, 600), rand:nextInteger(-600, 600))
			end

		end)
	end)

	Render:AddToQueue("Render", "Test", function()
		Lib.DrawRectangleRec(MainRect.Rectangle.Object, Const.GREEN)
		
		RectPool:Iterate(function(Object: System.Rectangle)
			Lib.DrawRectangleRec(Object.Object, Const.GOLD)
		end)
		
		TestRect:Iterate(function(Object, Index: number)
			Lib.DrawRectangleRec(Object.Object, Const.BEIGE)
		end)
	end)

	local RenderCode = Render:StartRender(); do
		Lib.CloseWindow()
		zune.process.exit(RenderCode)
	end

end; Main(Args)
