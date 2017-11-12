
local nullProfile = {
	int     = 0,
	str     = 0,
	agi     = 0,
	crit    = 0,
	vers    = 0,
	haste   = 0,
	leach   = 0,
	mastery = 0
}

-- constants | https://github.com/tekkub/wow-globalstrings/blob/master/GlobalStrings/enUS.lua
local stats = {
	int     = "ITEM_MOD_INTELLECT_SHORT",
	str     = "ITEM_MOD_STRENGTH_SHORT",
	agi     = "ITEM_MOD_AGILITY_SHORT",
	crit    = "ITEM_MOD_CRIT_RATING_SHORT",
	vers    = "ITEM_MOD_VERSATILITY",
	haste   = "ITEM_MOD_HASTE_RATING_SHORT",
	leach   = "ITEM_MOD_CR_LIFESTEAL_SHORT",
	mastery = "ITEM_MOD_MASTERY_RATING_SHORT"
}

local gems = {}
gems[1] = "EMPTY_SOCKET_BLUE";
gems[2] = "EMPTY_SOCKET_COGWHEEL";
gems[3] = "EMPTY_SOCKET_HYDRAULIC";
gems[4] = "EMPTY_SOCKET_META";
gems[5] = "EMPTY_SOCKET_NO_COLOR";
gems[6] = "EMPTY_SOCKET_PRISMATIC";
gems[7] = "EMPTY_SOCKET_RED";
gems[8] = "EMPTY_SOCKET_YELLOW";


local currentProfile = nullProfile

local primarytGem = 200;
local secondaryGem = 150

-- ========================================================
-- ONLOAD
-- ========================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
	 if event == "ADDON_LOADED" and arg1 == "GearScores" then

	 	print("GearScores Loaded..")
	 	-- ON LOAD
		checkSavedVars()
		updateCurrentProfile()
		creteTooltipHooks()

	end
end)	



function checkSavedVars () 

	
	if (GearScores_CurrentSelectedProfile == nil) then 
		GearScores_CurrentSelectedProfile = 1
	end

	if (GearScores_Profiles == nil) then 
		createNullProfile();
	end
end

function createNullProfile () 
	GearScores_Profiles = {}
	GearScores_Profiles[#GearScores_Profiles+1] = {
		name = "null",
		stats = nullProfile
	}
end


function updateCurrentProfile() 

	if(#GearScores_Profiles == 0)  then
		createNullProfile()
	end

	if(GearScores_CurrentSelectedProfile>#GearScores_Profiles) then
		GearScores_CurrentSelectedProfile = #GearScores_Profiles
	end
	
	currentProfile = GearScores_Profiles[GearScores_CurrentSelectedProfile].stats
	print(string.format("|cff2ae4c8GearScore Profile [%s] loaded.", GearScores_Profiles[GearScores_CurrentSelectedProfile].name))

end


function creteTooltipHooks () 
	GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    ShoppingTooltip1:HookScript("OnTooltipSetItem", OnTooltipSetItem);
    ShoppingTooltip2:HookScript("OnTooltipSetItem", OnTooltipSetItem);
end

function OnTooltipSetItem(self)

	local name, link = self:GetItem()

	if name then

		local equippable = IsEquippableItem(link)

		if equippable then

			local obj 	= createStats(link)
			local score = calculateScore(obj, currentProfile)
		
			self:AddLine("\nGear Score", 1, 0.5, 0,  1)
			self:AddLine("Base: ".. math.ceil(score) , 0.4, 0.8, 0.1,  1)

			if (hasSockets(link)) then


				local primaryStat, secondaryStat = getPrimaryAndSecondaryStat();

				local primGemScore =  math.ceil(calculateScoreWithGems(currentProfile, score, primaryStat, primarytGem))
				local secGemScore  =  math.ceil(calculateScoreWithGems(currentProfile, score, secondaryStat, secondaryGem))
				local strPrint1     = "Epic gem (+%s %s) : %s"				
				local strPrint2     = "Rare gem (+%s %s) : %s"				

				self:AddLine(string.format(strPrint1, primarytGem, primaryStat, primGemScore),   0.9, 0.45, 1,  1)
				self:AddLine(string.format(strPrint2, secondaryGem, secondaryStat, secGemScore), 0.4, 0.75, 1, 1)

			end

		end
	end
end


function createStats(itemLink) 
	local item = {}
	for key,value in pairs(stats) do 
		item[key] = getItemStat(itemLink, value)
	end
	return item
end


function getItemStat(itemLink, stateConst) 
	return GetItemStats(itemLink)[stateConst]
end


function calculateScore(itemStats, profile) 
	local score = 0
	for key,value in pairs(itemStats) do 
		if (value ~= 0) then
			score = score + (value * profile[key])
		end
	end
	return score
end

function calculateScoreWithGems (profile, score, attributeName, amout) 
	return score + (profile[attributeName] *amout)
end


-- Combain this (when it workes) with a calculate score with 200+ main stat and 150 + of some other stat.. maybe each gem types should be configurable

--[[
	200 gem = primary stat (int, agi, str)
	150 gem = secondary stat (master, crit, hast, vers)
]]

function getPrimaryAndSecondaryStat () 
	local profile = GearScores_Profiles[GearScores_CurrentSelectedProfile].stats

	local mainsStat 		 =  "int";
	local secondaryStat 	 = "mastery";
	local mainStatValue 	 = 0;
	local secondaryStatValue = 0;

	for key,value in pairs(profile) do 

		
		if (key == "int" or key == "str" or key == "agi") then

			if (tonumber(value) > mainStatValue) then
				mainsStat = key
				mainStatValue = tonumber(value)
			end

		elseif (key == "crit" or key == "vers" or key == "haste" or key == "leach" or key == "mastery")  then

			if (tonumber(value) > secondaryStatValue) then
				secondaryStat = key
				secondaryStatValue = tonumber(value)
			end
		end


	end

	--	print(string.format("main stat is %s:%s, secondaryStat: %s:%s", mainsStat, mainStatValue, secondaryStat, secondaryStatValue))
	return mainsStat, secondaryStat;

end

function hasSockets(itemLink)  
	local result = false
	for key,value in pairs(gems) do 
		if (getItemStat(itemLink, value) ~= nil) then
			result = true
		end
	end
	return result
end


function socketsCount (itemLink) 
	local numSockets = 0;
	for key,value in pairs(gems) do 
		if (getItemStat(itemLink, value) ~= nil) then
			numSockets = numSockets + getItemStat(itemLink, value);
		end
	end
	return numSockets
end

function getGems (itemLink) 

	local gem1name, gem1Link = GetItemGem(itemLink, 1)
	local gem2name, gem2Link = GetItemGem(itemLink, 2)
	local gem3name, gem3Link = GetItemGem(itemLink, 3)

	return gem1Link
end

-- ========================================================
-- Helpers
-- ========================================================


function getInputStat (input, stat) 
	-- Matches stats in the input string from the user
	-- getInputStat("v:0.1", "v") // 0.1
	local name, value = string.match(input , string.format('(%s):([0-9.]+)', stat))
	return (value or 0)
end


function getProfileName (input) 
	local profileName = string.match(input, "[a-z/_0-9\\-]+")
	return profileName
end


function removeCommandFromInput (input, command) 
	return string.gsub(input, command .. "%s+", "")
end


function removeStartingWhiteSpace (input) 
	return string.gsub(input, "^%s+", "" )
end


function sanitizeInput (input, command) 
	return removeStartingWhiteSpace(removeCommandFromInput(input, command))
end


function getSafeIndex (input) 
	local index = input
	if (index > #GearScores_Profiles) then
		index = #GearScores_Profiles
	end
	if (index < 1) then
		index = 1
	end
	return index
end;




-- ========================================================
-- SLASH COMMANDS 
-- ========================================================


function helpTextDefault () 
	 return "GearScores calculate a score based on stat weights, and show it in item tooltip\n" 
	.. "Commands:\n"
	.. "|cfffff800/gs list|r list all profiles\n"
	.. "|cfffff800/gs create|r create new profile\n"
	.. "|cfffff800/gs delete|r delete a profile\n"
	.. "|cfffff800/gs set|r set the active profile\n" 
	.. "|cfffff800/gs show|r  shows the profile and stats\n" 
	.. "|cfffff800 All commands can be used with help i.e: /gs help create\n"
end

SLASH_GEARSCORES1 = "/GS"
SlashCmdList["GEARSCORES"] = function(msg)

	

	-- remove whitespace in start of string
	local msg = removeStartingWhiteSpace(string.lower(msg))


	if (msg == nil or msg == "") then
		print(helpTextDefault())
	end

	if (string.find(msg, "^create") ~= nil ) then


		local sanitized = sanitizeInput(msg, "create")

		local newProfile = {

			name = getProfileName(sanitized),
			stats = {
				int     = getInputStat(sanitized, "i"),
				str     = getInputStat(sanitized, "s"),
				agi     = getInputStat(sanitized, "a"),
				crit    = getInputStat(sanitized, "c"),
				vers    = getInputStat(sanitized, "v"),
				haste   = getInputStat(sanitized, "h"),
				leach   = getInputStat(sanitized, "l"),
				mastery = getInputStat(sanitized, "m")
			}
		}
		

		GearScores_Profiles[#GearScores_Profiles+1] = newProfile
		GearScores_CurrentSelectedProfile = #GearScores_Profiles

		print("GearScore Profile Created:");
		print(" Profile Name: " ..  getProfileName(sanitized))
		print(" Stats Defined:")
		print(" - int: ".. getInputStat(sanitized, "i") )
		print(" - str: ".. getInputStat(sanitized, "s"))
		print(" - agi: ".. getInputStat(sanitized, "a"))
		print(" - crit: ".. getInputStat(sanitized, "c"))
		print(" - vers: ".. getInputStat(sanitized, "v"))
		print(" - haste: ".. getInputStat(sanitized, "h"))
		print(" - leach: ".. getInputStat(sanitized, "l"))
		print(" - mastery: ".. getInputStat(sanitized, "m"))
		print("\n")

		updateCurrentProfile();
	end

	if (string.find(msg, "^list") ~= nil ) then
		print("GearScore Profiles:")
		
		for key,value in pairs(GearScores_Profiles) do 	
			if (key == GearScores_CurrentSelectedProfile) then
				print(" |cfffff800=> [" .. key .."] ".. value.name)
			else
				print(" --  [" .. key .."] ".. value.name)
			end
		end

		print("\n")
	end

	if (string.find(msg, "^show") ~= nil ) then

		local index = getSafeIndex(tonumber(string.match(msg, "%d+") or GearScores_CurrentSelectedProfile));

		

		print("GearScore Profile: " .. GearScores_Profiles[index].name)


		for key, value in pairs(GearScores_Profiles[GearScores_CurrentSelectedProfile].stats) do
			print("- " .. key..": "..value)
		end

		print("\n")

	end

	if (string.find(msg, "^set") ~= nil ) then


		local index = getSafeIndex(tonumber(string.match(msg, "%d+") or 1));
		
		print(string.format("index before:%s", index ));

		GearScores_CurrentSelectedProfile = index
		updateCurrentProfile()
	end

	if (string.find(msg, "^delete") ~= nil ) then
		local index = getSafeIndex(tonumber(string.match(msg, "%d+") or 1));
		
		local item = GearScores_Profiles[index].name

		GearScores_Profiles[index] = nil;

		-- Create a new list of profiles so the indexes has the correct values 1,2,3 and not 1,5,6,9 or what ever randomness.
		local newProfiles = {}

		for key, value in pairs(GearScores_Profiles) do
			newProfiles[#newProfiles+1] = value
		end

		GearScores_Profiles = newProfiles;
		
		print(string.format("|cffff0000GearScore Removed profile: [#%s: %s], and updated the list", index, item));

		updateCurrentProfile();
	end



	if (string.find(msg, "^help") ~= nil ) then

		local subCommand = string.match(msg, "help%s([a-z]+)")
		local helpText = ""

		if (subCommand == nil) then
			helpText = helpTextDefault()
		end

		if (subCommand == "create") then
			helpText = "The Create Command: \n\n"
			.. "|cfffff800Syntax:|r\n"
			.. "/gs create <name><space><stats>\n\n"
			.. "example:\n"
			.. "/gs create affliction/warlock i:1,c:2,v:0.005,m:1.4\n\n"
			.. "|cfffff800Name:|r\n"
			.. "allowed chareters: [a-z0-9_-/] (no spaces allowed!)\n\n"
			.. "|cfffff800Stats:|r\n"
			.. "use the starting letter of each stat attribute, (if your class dosen't use a stat, just skip it.) and combine it with a value separated by a colon. separate each attribute/value pair with a comma. Avoid using spaces in the stats\n\n"
			.. "syntax:\n"
			.. "stat : value, ... \n\n"
			.. "example:\n"
			.. "i:2,c:1.4,v:0.04,h:3.10\n\n"
			.. "The supported stats are:\n"
			.. "[ |cffffdd00i|r ] int\n"    
			.. "[ |cffffdd00s|r ] str\n"    
			.. "[ |cffffdd00a|r ] agi\n"    
			.. "[ |cffffdd00c|r ] crit\n"   
			.. "[ |cffffdd00v|r ] vers\n"   
			.. "[ |cffffdd00h|r ] haste\n"  
			.. "[ |cffffdd00l|r ] leach\n"  
			.. "[ |cffffdd00m|r ] mastery\n\n"
		end
		
		if (subCommand == "delete") then
			helpText = "The Delete Command: \n\n"
			.. "/gs delete <num>\n"
			.. "delete the profile with the number\n"
		end

		if (subCommand == "set") then
			helpText = "The Set Command: \n\n"
			.. "/gs set <num>\n"
			.. "sets the profile with the number to the active profile\n"
		end

		if (subCommand == "show") then
			helpText = "The Show Command: \n\n"
			.. "/gs show <num | optional>\n"
			.. "default: shows the current profile with name and stats in an easy readable format\n"
			.. "if number is defined it will show the profile matching that number/index\n"
		end

		if (subCommand == "list") then
			helpText = "The List Command: \n\n"
			.. "/gs list\n"
			.. "list all profiles by name and the number used to select them, the current profile will be highlighted. \n"
		end

		print(helpText);
	end
end
