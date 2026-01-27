---------------------------------------
local Raylib = require("@raylib")
local task = zune.task
---------------------------------------
local lib = Raylib.lib
local Down = lib.IsKeyDown
local Up = lib.IsKeyUp
---------------------------------------
type Default = (DT: number) -> ()

export type InputHandle<Down = Default, Up = Default> = {
	read Toggle: (self: InputHandle, NewState: boolean?) -> (),
	State: boolean,

	read OnDown: (self: InputHandle, fn: Down) -> (),
	read OnUp: (self: InputHandle, fn: Up) -> (),

	write KeyDown: Down?,
	write KeyUp: Up?
}

type RegistryHandle<Down = Default, Up = Default> = {
	KeyDown: Down,
	KeyUp: Up
}

type InputRegistry<KeyList = { [string]: number }, MouseList = { Button: { any }, Cursor: { any } }> = {
	read Keyboard: KeyList,
	read Mouse: MouseList,
	Registries: {
		[number]: {
			[number]: InputHandle
		}
	},

	read RegisterChecker: thread,

	read RegisterKey: (self: InputRegistry, Key: string) -> InputHandle
}
---------------------------------------
local Keys = {
	NULL = 0,

	APOSTROPHE = 39,		PERIOD = 46,			ONE = 49,
	COMMA = 44,				SLASH = 47,				TWO = 50,
	MINUS = 45,				ZERO = 48,				THREE = 51,

	FOUR = 52,				SEVEN = 55,				SEMICOLON = 59,
	FIVE = 53,				EIGHT = 56,				EQUAL = 61,
	SIX = 54,				NINE = 57,

	A = 65,

	B = 66,		F = 70,		J = 74,
	C = 67,		G = 71,		K = 75,
	D = 68,		H = 72,		L = 76,
	E = 69,		I = 73,		M = 77,

	N = 78,		R = 82,		V = 86,
	O = 79,		S = 83,		W = 87,
	P = 80,		T = 84,		X = 88,
	Q = 81,		U = 85,		Y = 89,

	Z = 90,

	RIGHT_BRACKET = 93,		ESCAPE = 256,
	LEFT_BRACKET = 91,		GRAVE = 96,				ENTER = 257,
	BACKSLASH = 92,			SPACE = 32,				TAB = 258,

	BACKSPACE = 259,		RIGHT = 262,			UP = 265,
	INSERT = 260,			LEFT = 263,				PAGE_UP = 266,
	DELETE = 261,			DOWN = 264,				PAGE_DOWN = 267,

	HOME = 268,				SCROLL_LOCK = 281,		PAUSE = 284,
	END = 269,				NUM_LOCK = 282,			F1 = 290,
	CAPS_LOCK = 280,		PRINT_SCREEN = 283,		F2 = 291,

	F3 = 292,				F6 = 295,				F9 = 298,
	F4 = 293,				F7 = 296,				F10 = 299,
	F5 = 294,				F8 = 297,				F11 = 300,

	F12 = 301,				LEFT_ALT = 342,			RIGHT_CONTROL = 345,
	LEFT_SHIFT = 340,		LEFT_SUPER = 343,		RIGHT_ALT = 346,
	LEFT_CONTROL = 341,		RIGHT_SHIFT = 344,		RIGHT_SUPER = 347,

	KB_MENU = 348,			KP_2 = 322,				KP_5 = 325,
	KP_0 = 320,				KP_3 = 323,				KP_6 = 326,
	KP_1 = 321,				KP_4 = 324,				KP_7 = 327,

	KP_8 = 328,				KP_DIVIDE = 331,		KP_ADD = 334,
	KP_9 = 329,				KP_MULTIPLY = 332,		KP_ENTER = 335,
	KP_DECIMAL = 330,		KP_SUBTRACT = 333,		KP_EQUAL = 336,

	BACK = 4,
	MENU = 5,
	VOLUME_UP = 24,

	VOLUME_DOWN = 25,
}
---------------------------------------
local Mouse = {
	Button = {
		LEFT = 0,		SIDE = 3,
		RIGHT = 1,		EXTRA = 4,
		MIDDLE = 2,		FORWARD = 5,

		BACK = 6,
	},

	Cursor = {
		DEFAULT = 0,		CROSSHAIR = 3,
		ARROW = 1,			POINTING_HAND = 4,
		IBEAM = 2,			RESIZE_EW = 5,

		RESIZE_NS = 6,		RESIZE_ALL = 9,
		RESIZE_NWSE = 7,	NOT_ALLOWED = 10,
		RESIZE_NESW = 8,
	}
}
---------------------------------------
local Handle: InputHandle = {
	State = true,
	OnDown = function(self: InputHandle,fn: Default)
		self.KeyDown = fn
	end,

	OnUp = function(self: InputHandle, fn: Default)
		self.KeyUp = fn
	end,

	Toggle = function(self: InputHandle, NewState: boolean?)
		self.State = if NewState then NewState else not self.State
	end
}

---------------------------------------
local Registries: {RegistryHandle} = {}

local InputRegistry: InputRegistry<typeof(Keys), typeof(Mouse)> = {
	Keyboard = Keys,
	Mouse = {
		Button = Mouse.Button,
		Cursor = Mouse.Cursor,
	},

	RegisterChecker = (function()

		local Thread = coroutine.create(function()
			local DT: number = 0
			while true do DT = task.wait(1/90)
				for Key, Handle in Registries do
					local DCheck = Down(Key)
					local UCheck = Up(Key)
					if DCheck == 1 then
						Handle.KeyDown(DT)
					end

					if UCheck == 1 then
						Handle.KeyUp(DT)
					end
				end	
			end
		end); coroutine.resume(Thread)

		return Thread
	end)(),

	Registries = Registries :: any,

	RegisterKey = function(self: InputRegistry, Key: string): InputHandle
		local ValidKey = self.Keyboard[Key] 

		if not ValidKey then
			error(`Invalid Key, {Key} not found in key list. \n Add new keys if necessary or correct this if it's an error.`)
		end

		local NewHandle = table.clone(Handle)

		local Registry = self.Registries[ValidKey]

		if not Registry then
			self.Registries[ValidKey] = {}
		end

		table.insert(Registry, NewHandle)

		return NewHandle
	end
}
