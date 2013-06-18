local _G = getfenv(0);
local object = _G.object;

-- core is only used for initialization
local core = object.core;

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, tconcat, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.table.concat, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub;
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random, Vector3, HoN
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random, _G.Vector3, _G.HoN;

_G.HoNBots = _G.HoNBots or {};
_G.HoNBots.HeroData = _G.HoNBots.HeroData or {};

local mod = _G.HoNBots.HeroData;
mod.bDebug = true;

mod.tMemory = {};

-- We load all the bots into the HoNBots.HeroData Global since they're needed by both teams
-- We do this in the CoreInitialize since only then we can be sure both teams are exactly the way they'll remain
local oldCoreInitialize = core.CoreInitialize;
function core.CoreInitialize(botBrain, ...)
	local returnValue = oldCoreInitialize(botBrain, ...);
	
	mod:LoadTeamData(HoN.GetLegionTeam());
	mod:LoadTeamData(HoN.GetHellbourneTeam());
	
	return returnValue;
end

--[[ function mod:LoadTeamData(nTeamId)
description:		Load hero data for the provided team.
parameters:			nTeamId				(Number) The id of the team.
]]
function mod:LoadTeamData(nTeamId)
	for k, unit in pairs(HoN.GetHeroes(nTeamId)) do
		self:LoadHeroData(unit:GetTypeName());
	end
end

--[[ function mod:LoadHeroData(sTypeName)
description:		Load hero data for the hero.
parameters:			sTypeName			(String) The type name of the hero.
]]
function mod:LoadHeroData(sTypeName)
	if mod.bDebug or not self:GetHeroData(sTypeName) then -- Only try to add HeroData once (except during debugging)
		Echo('HeroData: Loading hero info for ^y' .. sTypeName .. '^*.');
		runfile('/bots/HeroData/' .. sTypeName .. '.lua');
	end
end

--[[ function mod:GetHeroData(sTypeName)
description:		Get the hero data for the hero.
parameters:			sTypeName			(String) The type name of the hero.
returns:			(HeroInfo) An instance of the HeroInfo containing the data. Nil if this doesn't exist.
]]
function mod:GetHeroData(sTypeName)
	return self[sTypeName];
end

--[[ function mod:HasInvis(nTeamId)
description:		Check if anyone in the provided team has an ability to turn himself or someone else invisible. Does not include items nor take into account cooldowns.
parameters:			nTeamId				(Number) The team identifier.
returns:			(Boolean) True if anyone in the team has an invis ability, false if not.
]]
function mod:HasInvis(nTeamId)
	for k, unit in pairs(HoN.GetHeroes(nTeamId)) do
		local hero = self:GetHeroData(unit:GetTypeName());
		
		if hero and hero:Has('TurnInvisible') then
			return true;
		end
	end
	
	return false;
end

--function mod:FilterAbilities(tAbilities, sPropertyName)
--	-- Filter the provided abilities table to only return those with sPropertyName
--	-- This way we can run this function several times per filter
--end

function mod:GetAllAbilities(nTeamId, tFilters)
	mod.tMemory[nTeamId] = mod.tMemory[nTeamId] or {};
	local tMemory = mod.tMemory[nTeamId];
	
	local sFilterIndex = tFilters and tconcat(tFilters, "|") or 'all';
	
	-- We assume heroes and their abilities stay the same during a match, so cache it and return cached objects if they're available
	if tMemory[sFilterIndex] then
		return tMemory[sFilterIndex];
	else
		tMemory[sFilterIndex] = {};
		
		local tAbilities = tMemory[sFilterIndex];
		
		-- Go through all heroes
		for k, unit in pairs(HoN.GetHeroes(nTeamId)) do
			local heroData = self:GetHeroData(unit:GetTypeName());
			
			if heroData then
				-- Go through all abilities
				for i = 0, 8 do
					local abilInfo = heroData:GetAbility(i);
					
					if abilInfo then
						local bPassAllRequirements = true;
						if tFilters then
							-- Go through all filters to make sure they're all not nil, false, nor 0
							for i = 1, #tFilters do
								local propVal = abilInfo[tFilters[i]];
								
								if not propVal or propVal == 0 then
									bPassAllRequirements = false;
									Echo(abilInfo:GetTypeName() .. ' failed on ' .. tFilters[i]);
									break;
								end
							end
						end
						
						if bPassAllRequirements then
							tinsert(tAbilities, abilInfo);
						end
					end
				end
			end
		end
		
		return tAbilities;
	end
end
