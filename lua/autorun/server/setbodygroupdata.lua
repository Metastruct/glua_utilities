local Tag = 'BodyGroupData'

util.AddNetworkString(Tag)

net.Receive(Tag, function(len, pl)
	local n = net.ReadUInt(24)
	n=n>2^24 and 2^24 or n
	if hook.Run("SetBodyGroupData",pl,n)==false then return end
	pl:SetBodyGroupData(n)
end)