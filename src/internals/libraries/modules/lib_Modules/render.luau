---------------------------------------
local raylib = require("@raylib")
local task: _zune_task = zune.task
---------------------------------------
local lib = raylib.lib
local const = raylib.const
---------------------------------------
export type ThreadDef = {
	read MainThread: thread, 
	Counter: number, 
	UpdateDelay: number
}

type Render = {
	FunctionQueue: {
		PreRender: {[string]: () -> ()},
		Render: {[string]: () -> ()},
		[string]: {[string]: () -> ()}
	},
	Counter: number,
	CanRender: boolean,

	SetCamera: (self: Render, Camera: raylib.Camera2D) -> (),
	GetCurrentCamera: (self: Render) -> raylib.Camera2D,
	MainCamera: raylib.Camera2D,

	RemoveFromQueue: (self: Render, Priority: string, Name: string) -> (),
	AddToQueue: (self: Render, Priority: string, Name: string, Function: () -> ()) -> (),

	AddThread: (self: Render, Name: string | number, ThreadTable: ThreadDef) -> (),
	RemoveThread: (self: Render, Name: string) -> (),
	ThreadQueue: {[string | number]: ThreadDef},

	StartRender: (self: Render) -> number
}
---------------------------------------
local Render = {
	FunctionQueue = {
		Render = {},
		PreRender = {}
	},
	Counter = 0,
	CanRender = true
} :: Render


function Render:SetCamera(Camera: raylib.Camera2D): ()
	self.MainCamera = Camera
end

function Render:GetCurrentCamera(): raylib.Camera2D
	return self.MainCamera
end

function Render:RemoveFromQueue(Priority: string, Name: string): ()
	if self.FunctionQueue[Priority][Name] then
		self.FunctionQueue[Priority][Name] = nil
	end
end

function Render:AddToQueue(Priority: string, Name: string, Function: () -> ()): ()
	if self.FunctionQueue[Priority][Name] then
		print("Overriding previous function, Named: "..Name)
	end

	self.FunctionQueue[Priority][Name] = Function
end

function Render:AddThread(Name, ThreadTable): ()
	self.ThreadQueue[Name] = ThreadTable
end

function Render:RemoveThread(Name): ()
	self.ThreadQueue[Name] = nil
end

Render.ThreadQueue = {}
---------------------------------------
local Timer: number = os.clock()

local ThreadUpdater: thread = task.spawn(function()
	while true do coroutine.yield()
		for Name, ThreadTable in Render.ThreadQueue do
			ThreadTable.Counter += 1
			if (ThreadTable.Counter) > ThreadTable.UpdateDelay then
				coroutine.resume(ThreadTable.MainThread)
				ThreadTable.Counter = 0
			end
		end
		
		if lib.WindowShouldClose() == 1 then
			Render.CanRender = false
		end
	end
end)
---------------------------------------
function Render:StartRender(): number
	while self.CanRender do self.Counter += 1

		for Name, func in self.FunctionQueue.PreRender do
			func()
		end

		lib.BeginDrawing(); do
		
			lib.ClearBackground(const.BLANK)

			lib.BeginMode2D(self.MainCamera); do
				--MainScope
				for Name, func in self.FunctionQueue.Render do
					func()
				end

			end; lib.EndMode2D()

		end; lib.EndDrawing()

		task.spawn(ThreadUpdater) ; task.wait(.0001) 
	end
	
	return 0
end


return Render