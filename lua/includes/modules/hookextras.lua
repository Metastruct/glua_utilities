if SERVER then
	AddCSLuaFile()
end


local functions = { }
local added = false
local function Stop()
	hook.Remove("Think", "NextThinkHelper")
end

local function error_func(line)
	ErrorNoHalt("NextThink: "..debug.traceback(line,2))
end

local function Think()
	local n = #functions
	if n == 0 then
		Stop()
		return
	end

	for i = 1, n do
		local func = table.remove(functions, 1)
		xpcall(func,error_func)
	end

end

local function Start()
	if added then
		return
	end

	hook.Add("Think", "NextThinkHelper", Think)
end

function RunNextThink(func)
	if not isfunction(func) then
		error("Expected function", 2)
	end

	functions[#functions + 1] = func
	Start()
end

NextThink = RunNextThink
util.NextThink = NextThink
util.NextFrame = NextThink

-- OnInitialize

local functions = { }
local initialized = false

local function error_func(line)
	ErrorNoHalt("OnInitialize: " .. debug.traceback(line, 2))
end

local function Initialize()
	
	initialized = true
	
	for i = 1, #functions do
		local func = functions[i]
		xpcall(func, error_func)
	end

	functions = nil
	hook.Remove("Initialize", "RunOnInitializeHelper")
end


function RunOnInit(func)
	if not isfunction(func) then
		error("Expected function", 2)
	end
	
	if not functions then
		timer.Simple(0,func)
		return
	end
	
	functions[#functions + 1] = func
end
RunOnInitialize = RunOnInit
OnInitialize = RunOnInit
util.OnInitialize = RunOnInit

hook.Add("Initialize", "RunOnInitializeHelper", Initialize)


if CLIENT then

	-- OnLocalPlayer

	local functions = { }
	local initialized = false

	local function error_func(line)
		ErrorNoHalt("OnLocalPlayer: " .. debug.traceback(line, 2))
	end

	local function OnEntityCreated(ent)

		local me = LocalPlayer()
		if ent~=me then return end
		assert(not initialized)
		initialized = true
		
		for i = 1, #functions do
			local func = functions[i]
			xpcall(func, error_func, me)
		end

		functions = nil
		hook.Remove("OnEntityCreated", "OnLocalPlayer")
	end


	local function util_OnLocalPlayer(func)
		if not isfunction(func) then
			error("Expected function", 2)
		end
		
		if not functions then
			timer.Simple(0,function() func(LocalPlayer()) end)
			return
		end
		
		functions[#functions + 1] = func
	end

	util.OnLocalPlayer = util_OnLocalPlayer

	hook.Add("OnEntityCreated", "OnLocalPlayer", OnEntityCreated)

end