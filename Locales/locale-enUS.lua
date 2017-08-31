-- Achieve Channel enUS localization by: Chaoslux

local L = LibStub("AceLocale-3.0"):NewLocale("AchieveChannel2", "enUS", true)
if not L then return end

L["ACHIEVEMENT_EARNED"] = "has earned the achievement:"
L["Achievement Link"] = "Show Achievement Link in announcements"
L["Achievement Link Desc"] = "If Enabled, announcements will have a clickable achievement link, otherwise it will only say the name of the achievement."
L["Announcement Settings Desc"] = "Choose the channels you wish to announce when you get achievements, as we ll as customize what gets announced."
L["Announcements Settings"] = true
L["Channel Enable"] = "Enable Announcing in this channel"
L["Channel Enable Desc"] = "If enabled, you will announce to %s every time you get an achievement."
L["Disable Annoucements"] = true
L["Disable Announcements Desc"] = "If this is checked, it will override all channel settings and this addon will do nothing."
L["Feats of Strength"] = "Announce Feats of Strength"
L["Feats of Strength Desc"] = "If Enabled, Feats of Strength will be announced. Any achievements that gives 0 achievement point is considered a feat of strength."
L["Filter Guildmates"] = true
L["Filter Guildmates Desc"] = "When enabled, you will not see guildmates announcements in custom channel since you will see them in guild chat."
L["Filter Yourself"] = true
L["Filter Yourself Desc"] = [=[When enabled, this will prevent you from seeing your channel announcements. 

Note that the first announcement on any character will never be filtered.]=]
L["Global Settings"] = true
L["GUILD_ACHIEVEMENT_EARNED"] = "has earned the guild achievement:"
L["Guild Achievements"] = "Announce Guild Achievements"
L["Guild Achievements Desc"] = "If Enabled, Guild achievements will be announced as well. The announcement will be altered to show that it is a guild achievement."
L["Only High Achievements"] = "Only announce achievements worth 15 points or more"
L["Only High Achievements Desc"] = "If Enabled, achievements worth 5 or 10 points will not be announced. This setting will not affect Feats of Strengths or Guild Achievements."
