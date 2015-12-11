function BetterLightFX:GetSaveFile()
    return self.SavePath .. self.name .. "options.txt"
end

local Options = BetterLightFX.Options
function BetterLightFX:Save()
	local fileName = self:GetSaveFile()
	local file = io.open(fileName, "w+")
	file:write(json.encode(Options))
	file:close()
end

function BetterLightFX:LoadOptions()
	local file = io.open(self:GetSaveFile(), 'r')
	if file == nil then
		return
	end
	local file_contents = file:read("*all")
	local data = json.decode( file_contents )
	file:close()
	if data then
		BetterLightFX:OverwriteOptionValues(Options, data)
	end
end

function BetterLightFX:OverwriteOptionValues(OptionTable, NewOptionTable)
	for i, data in pairs(NewOptionTable) do
		if type(data) == "table" and OptionTable[i] then
			OptionTable[i] = table.merge(OptionTable[i], data)
		else
			OptionTable[i] = data
		end
	end
	return OptionTable

end