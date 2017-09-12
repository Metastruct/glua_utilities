if SERVER then
	AddCSLuaFile()
end

do -- is stuck checker

	local output = {}
	local pl_filt
	local filter_tbl  = {}
	local function filter_func(e)
		if e==pl_filt then return false end
		local cg = e:GetCollisionGroup()

		return
			cg~=15 -- COLLISION_GROUP_PASSABLE_DOOR
		and cg~=11 -- COLLISION_GROUP_WEAPON
		and cg~=1 -- COLLISION_GROUP_DEBRIS
		and cg~=2 -- COLLISION_GROUP_DEBRIS_TRIGGER
		and cg~=20 -- COLLISION_GROUP_WORLD

	end
	local t = {output = output ,mask=MASK_PLAYERSOLID}
	FindMetaTable"Player".IsStuck=function(pl,fast,pos)
		t.start = pos or pl:GetPos()
		t.endpos = t.start
		if fast then
			filter_tbl[1] = pl
			t.filter = filter_tbl
		else
			pl_filt = pl
			t.filter = filter_func
		end


		util.TraceEntity(t,pl)
		return output.StartSolid,output.Entity,output
	end

end


--------------

local Tag = "player_cache"

local next=next

local cache = player.GetAllCached and player.GetAllCached() or {}
local cache_count = player.CountAll and player.CountAll() or 0

function player.GetAllCached()
	return cache
end
function player.CountAll()
	return cache_count
end

function player.All()
	return next,cache
end

function player.iterator()
	local i=1
	local function iter_all()
		local val=cache[i]
		i=val and i+1 or 1
		return val
	end
	return iter_all
end


local SERVER=SERVER

local function EntityCreated(pl)
	--assert(pl:IsPlayer()==pl:IsPlayer(),"isplayer mismatch")
	if pl:IsPlayer() then
		--print("Creating", pl)
		if SERVER then
			local uid = pl:UserID()
			for k, v in next, cache do
				if uid == v:UserID() then

					table.remove(cache, k)
					cache_count = cache_count - 1
				   -- print("NOCREAET, CACHE REMOVE", pl:UserID(), pl)
					return
				end

			end

		end

		table.insert(cache, pl)
		cache_count = cache_count + 1
	end

end

if SERVER then
	hook.Add("OnEntityCreated", Tag, EntityCreated)
else
	hook.Add("NetworkEntityCreated", Tag, EntityCreated)
end

local function add(pl)
	for k,pl2 in next,cache do
		if pl2==pl then return end
	end
	table.insert(cache,pl)
	cache_count = cache_count + 1
end
for k, pl in next, player.GetAll() do
	add(pl)
end

local function EntityRemoved(pl)
	--assert(pl:IsPlayer()==pl:IsPlayer(),"isplayer mismatch")
	if pl:IsPlayer() then
		--print("Removing", pl)
		for k, v in next, cache do
			if pl == v then
				table.remove(cache, k)
				cache_count = cache_count - 1
				-- return -- Add or not? Recursion even?
			end

		end

	end

end

if SERVER then
	hook.Add("PlayerDisconnected", Tag, EntityRemoved)
end
hook.Add("EntityRemoved", Tag, EntityRemoved)




--[[ testing --


local function assertfind(t, pl)
	for k, v in next, t do
		if v == pl then
			return
		end

	end

	error("Did not find: " .. tostring(pl) .. ' - ' .. tostring(player.ToUserID(pl)) .. ' - ' .. tostring(player.UserIDToName(player.ToUserID(pl))) .. ' from ' .. (t == player.GetAllCached() and "cachetbl" or "playerall"))
end

hook.Add("Think", Tag, function()
	local t = player.GetAll()
	local t2 = player.GetAllCached()
	for k, v in next, t do
		assert(IsValid(v), "getall not valid")
		assert(v:IsPlayer(), "getall not valid IsPlayer1")
		assert(v:IsPlayer(), "getall not valid IsPlayer2")
		assertfind(t2, v)
	end

	for k, v in next, t2 do
		assert(IsValid(v), "cache not valid")
		assert(v:IsPlayer(), "cache not valid IsPlayer1")
		assert(v:IsPlayer(), "cache not valid IsPlayer2")
		assertfind(t, v)
	end

end)

--]]


-------------------------------------

local Tag = 'PlayerSlowThink'
--By: Python1320, original by Lixquid

local RealTime = RealTime
local player = player
local hook = hook
local next = next
local FrameTime = FrameTime
local math = math
local ticint
	local function getintervals()
		return ticint
	end

	local function getintervalc()
		local ft = FrameTime()
		return ft > 0.3 and 0.3 or ft
	end

	local getinterval
	getinterval = function()
		if SERVER then
			ticint = engine.TickInterval()
			getinterval = getintervals
		else
			getinterval = getintervalc
		end

		return getinterval()
	end

local iterating_players = {  }
local function refreshplayers(t)
	local pls = player.GetAllCached()
	local plsc = #pls
	for i = 1, plsc do
		iterating_players[i] = pls[i]
	end

	local ipc = #iterating_players
	if ipc == plsc then
		return plsc
	end

	for i = ipc, plsc + 1, -1 do
		iterating_players[i] = nil
	end

	return plsc
end

function GetPlayerThinkCache()
	return iterating_players
end

local function Call(pl)
	if not pl:IsValid() then
		return
	end

	hook.Call(Tag, nil, pl)
end

local iterid = 1
local function iter()
	iterid = iterid + 1
	local pl = iterating_players[iterid]
	if pl == nil then
		iterid = 1
		return true
	end

	Call(pl)
end

local iterations_per_tick
local iterations_per_tick_frac
local fracpart = 0
local nextthink = 0
local printed
local function Think()
	local pl = iterating_players[iterid]
	if pl == nil then
		local now = RealTime()
		if nextthink > now then
			--if not printed then
			--	printed = true
			--	--print("=========",nextthink - now)
			--end

			return
		end

		nextthink = now + 1
		--printed = false
		fracpart = fracpart >= 1 and 1 or fracpart
		local plc = refreshplayers(iterating_players)
		if plc == 0 then
			return
		end

		iterid = 1
		iterations_per_tick = #player.GetAllCached() * getinterval()
		iterations_per_tick_frac = iterations_per_tick - math.floor(iterations_per_tick)
		iterations_per_tick = math.floor(iterations_per_tick)
		pl = iterating_players[iterid]
		if pl == nil then
			return
		end
		if fracpart>=0.3 then
			fracpart = 0
			Call(pl)
			iterid = iterid + 1
			pl = iterating_players[iterid]
			if pl == nil then
				return
			end
		end
	end

	fracpart = fracpart + iterations_per_tick_frac
	if fracpart > 1 then
		fracpart = fracpart - 1
		Call(pl)
		iterid = iterid + 1
		pl = iterating_players[iterid]
		if pl == nil then
			return
		end

	end

	for i = 1, iterations_per_tick do
		Call(pl)
		iterid = iterid + 1
		pl = iterating_players[iterid]
		if pl == nil then
			return
		end

	end

end


hook.Add("Think", Tag, Think)


-- Fix parent positioning function --

local Tag="f_pp"
if SERVER then

	util.AddNetworkString(Tag)

	local Entity=FindMetaTable"Entity"
	function Entity:FixParentPositioning()

		local ply = self:GetParent()
		if not ply:IsPlayer() then error"Parent is not a player" end

		net.Start(Tag)
			net.WriteEntity(self)
		net.Send(ply)
	end

end


-- player revive
if SERVER then
	local Player = FindMetaTable"Player"
	Player.Revive=Player.Revive or function(pl)
		if pl:Alive() then return end
		local pos = pl:GetPos()
		pl:Spawn()
		pl:SetPos(pos)
	end
end

if SERVER then return end

local t={}

local added = false

local LocalPlayer=LocalPlayer

local function PreDrawOpaqueRenderables()
	local mypos=LocalPlayer():GetPos()
	local ok
	for _,ent in next,t do
		ok=true
		if not ent:IsValid() then
			t[_]=nil
			continue
		end
		ent:SetRenderAngles(ent:GetNetworkAngles())
		ent:SetRenderOrigin(ent:GetNetworkOrigin()+mypos)
	end
	if not ok then
		added=false
		hook.Remove("PreDrawOpaqueRenderables",Tag)
	end
end

net.Receive(Tag,function()
	if not added then
		hook.Add("PreDrawOpaqueRenderables",Tag,PreDrawOpaqueRenderables)
		added = true
	end

	local ent = net.ReadEntity()

	if not IsValid(ent) then return end

	table.insert(t,ent)

end)

player.GetByUserID = player.GetByID

