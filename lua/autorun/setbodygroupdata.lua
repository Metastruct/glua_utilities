local Tag = 'SetBodyGroupData'


FindMetaTable"Player".SetBodyGroupData = SERVER and function(self, n)
	self:SetSaveValue("SetBodyGroup", n)
end or function(self, n)
	if self ~= LocalPlayer() then return end
	net.Start(Tag)
		net.WriteUInt(n or 0, 24)
	net.SendToServer()
end