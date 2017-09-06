local Tag = 'SetBodyGroupData'

if SERVER then
	util.AddNetworkString(Tag)

	net.Receive(Tag, function(len, pl)
		local n = net.ReadUInt(24)
		n=n>2^24 and 2^24 or n
		if hook.Run("SetBodyGroupData",pl,n)==false then return end
		pl:SetBodyGroupData(n)
	end)
end

FindMetaTable"Player".SetBodyGroupData = SERVER and function(self, n)
	self:SetSaveValue("SetBodyGroup", n)
end or function(self, n)
	if self ~= LocalPlayer() then return end
	net.Start(Tag)
		net.WriteUInt(n or 0, 24)
	net.SendToServer()
end