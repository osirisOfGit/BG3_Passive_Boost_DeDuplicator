Ext.Require("Utilities/Common/_Index.lua")

Logger:ClearLogFile()

---@param entity EntityHandle
---@return string
local function GetEntityName(entity)
	if Logger:IsLogLevelEnabled(Logger.PrintTypes.DEBUG) then
		local char = entity.ServerCharacter or entity.ClientCharacter
		return (entity.DisplayName and entity.DisplayName.Name:Get())
			or (char and (char.Template and char.Template.DisplayName:Get()))
			or entity.Uuid.EntityUuid
	end
	return "How?"
end

---@param entity EntityHandle
---@diagnostic disable-next-line: param-type-mismatch
Ext.Entity.Subscribe("BoostsContainer", function(entity)
	if entity:IsAlive() then
		local log = "\n"
		log = log .. ("========== Checking Entity %s (%s) =========="):format(GetEntityName(entity), entity.Uuid.EntityUuid)
		local removedBoosts = false
		for _, boostEntry in pairs(entity.BoostsContainer.Boosts) do
			---@type {[string]: {[string]: EntityHandle[]}}
			local passiveTable = {}
			for _, boost in pairs(boostEntry.Boosts) do
				local boostInfo = boost.BoostInfo
				if boostInfo and boostInfo.Cause.Type == "Passive" then
					if passiveTable[boostInfo.Cause.Cause] then
						if passiveTable[boostInfo.Cause.Cause][boostInfo.Prototype] then
							table.insert(passiveTable[boostInfo.Cause.Cause][boostInfo.Prototype], boost)
						else
							passiveTable[boostInfo.Cause.Cause][boostInfo.Prototype] = {boost}
						end
					else
						passiveTable[boostInfo.Cause.Cause] = { [boostInfo.Prototype] = {boost} }
					end
				end
				-- Ext.System.ServerBoost.DetachAndDestroyBoost[boost] = true
			end
			for passiveId, prototypes in pairs(passiveTable) do
				for prototype, boostEntities in pairs(prototypes) do
					if #boostEntities > 1 then
						removedBoosts = true
						log = log .. ("\nPassive %s is duplicated with %d total boosts under Prototype Id %s, clearing all but the first"):format(passiveId, #boostEntities, prototype)
						for b = #boostEntities, 2, -1 do
							Ext.System.ServerBoost.DetachAndDestroyBoost[boostEntities[b]] = true
						end
					end
				end
			end
		end
		log = log .. ("\n========== Finished Entity %s =========="):format(GetEntityName(entity))

		if removedBoosts then
			Logger:BasicDebug(log)
		end
	end
end)
