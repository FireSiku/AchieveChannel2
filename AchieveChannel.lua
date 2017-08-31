--[[
	Project....: AchieveChannel2
	File.......: AchieveChannel.lua
	Description: Shows Achievements earned in custom/private channels. 
	Version....: 2.0
	Rev Date...: 10/07/12 [dd/mm/yy]
]] 

---------------------
-- Local Variables --
---------------------
local addonName = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local options = {}
local db

local format, pairs = format, pairs
local strlower, strfind = string.lower, string.find
local GetAchievementInfo = GetAchievementInfo
local UnitIsInMyGuild = UnitIsInMyGuild
local SendChatMessage = SendChatMessage
local GetChannelName = GetChannelName

local activeChanList = {}
local optionChanList = {}
local announceChanList = {}

local playerName  -- Calling UnitName for every achievmeent sounds pointless, keep it stored.

--Setup Defaults
local defaults = {
	profile = {
		Enable = true,
		filterYou = true,
		filterGuild = true,
		hasAchieve = false,
		chanList = {
			['*'] = {
				Enable = false,
				onlyHigh = false,
				showGuild = true,
				showFOS = true,
				achLink = true,
			},
		},
	},
}

---------------------
-- Addon Functions --
--------------------- 

local function SendChannelMessage(channel, text)
	SendChatMessage(text, "CHANNEL", nil, GetChannelName(channel));
end

local function filterFunc(ChatFrameSelf, event, msg, nick, ...)
	-- Make sure there's a message and a nick, who knows if something goes wrong.
	-- Also, make sure that you have at least one channel in your chanList before filtering.
	if msg and nick and #announceChanList > 0 then
		--Check if it's an achievement message.
		if strfind(msg, L["ACHIEVEMENT_EARNED"]..".*!$") or strfind(msg, L["GUILD_ACHIEVEMENT_EARNED"]..".*!$") then
			--Check to make sure not to filter the first achievement.
			if db.hasAchieve then
				if UnitIsInMyGuild(nick) and db.filterGuild and not nick == playerName then
					return true;
				end
				if nick == playerName and db.filterYou then
					return true;
				end
			else
				db.hasAchieve = true
			end
		end	
	end
end

local serverList
local function IsOfficialChannel(chanName)
	if not serverList then serverList = { EnumerateServerChannels() } end
	for i=1, #serverList do
		if chanName == serverList[i] then return true end
	end
	--Hack: Enumate doesn't list Trade Chat, add it manually
	if chanName == "Trade" then return true end
end

local function RefreshChannelList()
	local aclist = { GetChannelList() }
	wipe(activeChanList)
	--Odd numbered returns are used for channel numbers. We just want the names.
	for i=2, #aclist, 2 do
		if not IsOfficialChannel(aclist[i]) then
			--Add channel to active list.
			activeChanList[#activeChanList+1] = aclist[i]
		end-
	end
end

local function RefreshAnnounceList()
	--Keeping a list of announced channels prevents having to check all channels for Enabled
	wipe(announceChanList)
	for i=1, #activeChanList do
		if db.chanList[ strlower( activeChanList[i] ) ].Enable then
			announceChanList[#announceChanList+1] = activeChanList[i]
		end
	end
end

local function RefreshBothList()
	RefreshChannelList() 
	RefreshAnnounceList()
end

-------------------
--  Addon Events --
-------------------

function addon:ACHIEVEMENT_EARNED(self, id)

	local _, name, points, completed, _, _, _, _, _, _, _, isGuild = GetAchievementInfo(id)
	local achLink = GetAchievementLink(id)
	local achText = L["ACHIEVEMENT_EARNED"]
	if isGuild then achText = L["GUILD_ACHIEVEMENT_EARNED"] end

	-- Diasplay the achievement if enabled
	if completed and db.Enable then
		local ok = true -- Binary variable to check conditions.

		--Go through all enabled channels to see if it matches channel specific criterias
		for _, chan in pairs(announceChanList) do
			ok = true
			if ok and isGuild and not db.chanList[chan].showGuild then ok = false end
			if ok and points == 0 and not db.chanList[chan].showFOS then ok = false end
			if ok and not isGuild and (points == 5 or points == 10) and db.chanList[chan].onlyHigh then ok = false end
			
			--Pass all checks, announce achievement
			if ok then 
				if db.chanList[chan].achLink then
					SendChannelMessage(chan, achText.." "..achLink.."!")
				else SendChannelMessage(chan,achText.." ["..name.."]!")
				end
				
			end
		end
	end

end

-------------------
-- Addon Options -- 
-------------------

--Options Table
local function GenerateChannelOptions(arg)
	--Fill the active channel list.
	RefreshChannelList()

	--arg can be a function to the option table, or the table itself.
	local option = (type(arg) == "function") and arg() or arg
	option = option.args.General.args

	--Remove channels that arent active anymore.
	for i=1,#optionChanList do
		option[optionChanList[i]] = nil
	end

	--Generate options based on channel list
	for i=1, #activeChanList do
		local chan = strlower(activeChanList[i])
		local chanNum = GetChannelName(activeChanList[i])
		option[chan] = {}
		option[chan].name = chanNum..". "..chan
		option[chan].type = "group"
		option[chan].order = i+10
		option[chan].disabled = function(info) return not db.Enable end
		option[chan].get = function(info) return db.chanList[chan][ info[#info] ] end
		option[chan].set = function(info, value) db.chanList[chan][ info[#info] ] = value end
		option[chan].args = {
			Enable = {
				name = L["Channel Enable"],
				desc = format(L["Channel Enable Desc"],chan),
				type = "toggle",
				width = "full",
				order = 1,
				set = function(info,value)
					db.chanList[chan][ info[#info] ] = value
					RefreshAnnounceList()
				end

			},
			showGuild = {
				name = L["Guild Achievements"],
				desc = L["Guild Achievements Desc"],
				type = "toggle",
				width = "full",
				order = 2,
				hidden = function(info) return not db.chanList[chan].Enable end,
			},
			showFOS = {
				name = L["Feats of Strength"],
				desc = L["Feats of Strength Desc"],
				type = "toggle",
				width = "full",
				order = 3,
				hidden = function(info) return not db.chanList[chan].Enable end,
			},
			achLink = {
				name = L["Achievement Link"],
				desc = L["Achievement Link Desc"],
				type = "toggle",
				width = "full",
				order = 4,
				hidden = function(info) return not db.chanList[chan].Enable end,
			},
			onlyHigh = {
				name = L["Only High Achievements"],
				desc = L["Only High Achievements Desc"],
				type = "toggle",
				width = "full",
				order = 5,
				hidden = function(info) return not db.chanList[chan].Enable end,
			},
		}
		
		--Add to option pool. 
		optionChanList[#optionChanList+1] = chan
	end
end

local function LoadOptions()
	if (not options.args) then

	options = {
		type = "group",
		name = addonName,
		get = function(info) return db[ info[#info] ] end,
		set = function(info, value) db[ info[#info] ] = value end,
		args = {
			--start of general options
			General = {
				order = 1,
				type = "group",
				name = "General",
				args = {
					globalSettingHeader = {
						order = 1,
						type = "header",
						name = L["Global Settings"],
					},
					Enable = {
						name = L["Disable Annoucements"],
						desc = L["Disable Announcements Desc"],
						type = "toggle",
						order = 4,
						get = function(info) return not db[ info[#info] ] end,
						set = function(info, value) db[ info[#info] ] = not db[ info[#info] ] end,
					},
					filterYou = {
						name = L["Filter Yourself"],
						desc = L["Filter Yourself Desc"],
						type = "toggle",
						order = 2,
					},
					filterGuild = {
						name = L["Filter Guildmates"],
						desc = L["Filter Guildmates Desc"],
						type = "toggle",
						order = 3,
					},
					annByChannelHeader = {
						order = 5,
						type = "header",
						name = L["Announcements Settings"],
					},
					annByChannelText = {
						order = 6,
						type = "description",
						name = L["Announcement Settings Desc"],
					},
					-- Channel List Options are under GenerateChannelOptions
				},
			},
			--end of general options
		},
	}
	
	GenerateChannelOptions(options)
	
	end
	return options
end

function addon:SetupOptions()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, LoadOptions);
	options.General = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, nil, nil, "General")
end

--Addon Loaded
function addon:OnInitialize()
	
	--Setup Database
	self.db = LibStub("AceDB-3.0"):New("AchieveChannelDB",defaults)
	db = self.db.profile

	addon:SetupOptions()
	self:RegisterChatCommand( addonName, "ChatCommand")
	self:RegisterChatCommand( "ac", "ChatCommand")
end

function addon:OnEnable()

	addon:RegisterEvent("ACHIEVEMENT_EARNED")
	self:RegisterBucketEvent("CHANNEL_UI_UPDATE", 0.1, RefreshBothList)
	
	--Add Filter Function
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
	
	--Call those because CHANNEL_UI_UPDATE doesnt trigger upon login
	RefreshBothList()
	
	playerName = UnitName("Player").."-"..GetRealmName()
end

function addon:ChatCommand(input)
	GenerateChannelOptions(LoadOptions)
	InterfaceOptionsFrame_OpenToCategory("AchieveChannel2")
	InterfaceOptionsFrame_OpenToCategory("AchieveChannel2")
end