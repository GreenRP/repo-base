-- Made by: Nnoggie - Tarren Mill <Method>, 2017-2019
local AddonName, MethodDungeonTools = ...
local L = MethodDungeonTools.L

local mainFrameStrata = "HIGH"
local canvasDrawLayer = "BORDER"

_G["MethodDungeonTools"] = MethodDungeonTools

local twipe,tinsert,tremove,tgetn,CreateFrame,tonumber,pi,max,min,atan2,abs,pairs,ipairs,GetCursorPosition,GameTooltip = table.wipe,table.insert,table.remove,table.getn,CreateFrame,tonumber,math.pi,math.max,math.min,math.atan2,math.abs,pairs,ipairs,GetCursorPosition,GameTooltip
local SetPortraitTextureFromCreatureDisplayID,MouseIsOver = SetPortraitTextureFromCreatureDisplayID,MouseIsOver

local sizex = 840
local sizey = 555

local methodColor = "|cFFF49D38"
MethodDungeonTools.BackdropColor = {0.058823399245739,0.058823399245739,0.058823399245739,0.9}

local Dialog = LibStub("LibDialog-1.0")
local AceGUI = LibStub("AceGUI-3.0")
local db
local icon = LibStub("LibDBIcon-1.0")
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("MethodDungeonTools", {
	type = "data source",
	text = L"Method Dungeon Tools",
	icon = "Interface\\AddOns\\MethodDungeonTools\\Textures\\MethodMinimap",
	OnClick = function(button,buttonPressed)
		if buttonPressed == "RightButton" then
			if db.minimap.lock then
				icon:Unlock("MethodDungeonTools")
			else
				icon:Lock("MethodDungeonTools")
			end
		else
			MethodDungeonTools:ShowInterface()
		end
	end,
	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		tooltip:AddLine(methodColor.."Method Dungeon Tools|r")
		tooltip:AddLine(L"Click to toggle AddOn Window")
		tooltip:AddLine(L"Right-click to lock Minimap Button")
	end,
})

SLASH_METHODDUNGEONTOOLS1 = "/mplus"
SLASH_METHODDUNGEONTOOLS2 = "/mdt"
SLASH_METHODDUNGEONTOOLS3 = "/methoddungeontools"

function SlashCmdList.METHODDUNGEONTOOLS(cmd, editbox)
	local rqst, arg = strsplit(' ', cmd)
	if rqst == "devmode" then
		MethodDungeonTools:ToggleDevMode()
	elseif rqst == "reset" then
        MethodDungeonTools:ResetMainFramePos()
	elseif rqst == "dc" then
        MethodDungeonTools:ToggleDataCollection()
    elseif rqst == "hptrack" then
        MethodDungeonTools:ToggleHealthTrack()
    else
		MethodDungeonTools:ShowInterface()
	end
end

local initFrames
-------------------------
--- Saved Variables  ----
-------------------------
local defaultSavedVars = {
	global = {
        toolbarExpanded = true,
        currentSeason = 4,
		currentExpansion = 2,
        scale = 1,
        enemyForcesFormat = 2,
        enemyStyle = 1,
		currentDungeonIdx = 15,
		currentDifficulty = 10,
		xoffset = 0,
		yoffset = -150,
        defaultColor = "228b22",
		anchorFrom = "TOP",
		anchorTo = "TOP",
        tooltipInCorner = false,
		minimap = {
			hide = false,
		},
        toolbar ={
            color = {r=1,g=1,b=1,a=1},
            brushSize = 3,
        },
		presets = {},
		currentPreset = {},
		dataCollectionActive = false,
		colorPaletteInfo = {
            autoColoring = true,
            forceColorBlindMode = false,
            colorPaletteIdx = 4,
            customPaletteValues = {},
            numberCustomColors = 12,
        },
	},
}
do
    for i=1,26 do
        defaultSavedVars.global.presets[i] = {
            [1] = {text="Default",value={},colorPaletteInfo={autoColoring=true,colorPaletteIdx=4}},
            [2] = {text="<New Preset>",value=0},
        }
        defaultSavedVars.global.currentPreset[i] = 1
    end
end

-- Init db
do
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    --TODO Register Affix Changed event
    frame:SetScript("OnEvent", function(self, event, ...)
        return MethodDungeonTools[event](self,...)
    end)

    function MethodDungeonTools.ADDON_LOADED(self,addon)
        if addon == "MethodDungeonTools" then
			db = LibStub("AceDB-3.0"):New("MethodDungeonToolsDB", defaultSavedVars).global
			icon:Register("MethodDungeonTools", LDB, db.minimap)
			if not db.minimap.hide then
				icon:Show("MethodDungeonTools")
			end
			Dialog:Register("MethodDungeonToolsPosCopyDialog", {
				text = "Pos Copy",
				width = 500,
				editboxes = {
					{ width = 484,
					  on_escape_pressed = function(self, data) self:GetParent():Hide() end,
					},
				},
				on_show = function(self, data)
					self.editboxes[1]:SetText(data.pos)
					self.editboxes[1]:HighlightText()
					self.editboxes[1]:SetFocus()
				end,
				buttons = {
					{ text = CLOSE, },
				},
				show_while_dead = true,
				hide_on_escape = true,
			})
            if db.dataCollectionActive then MethodDungeonTools.DataCollection:Init() end
            --fix db corruption
            do
                for _,presets in pairs(db.presets) do
                    for presetIdx,preset in pairs(presets) do
                        if presetIdx == 1 then
                            if preset.text ~= "Default" then
                                preset.text = "Default"
                                preset.value = {}
                            end
                        end
                    end
                end
                for k,v in pairs(db.currentPreset) do
                    if v <= 0 then db.currentPreset[k] = 1 end
                end
            end
            for _, d in pairs(MethodDungeonTools.dungeonEnemies) do
                for _, v in pairs(d) do
                    local name = L.NPCS[v.id] if name then v.name = name end
                    local name = L.CREATURES[v.creatureType] if name then v.creatureType = name end
                end
            end
            L.NPCS, L.CREATURES = nil, nil
            --register AddOn Options
            MethodDungeonTools:RegisterOptions()
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
    local last = 0
    function MethodDungeonTools.GROUP_ROSTER_UPDATE(self,addon)
        --check not more than once per second (blizzard event spam)
        local now = GetTime()
        if last < now - 1 then
            if not MethodDungeonTools.main_frame then return end
            local inGroup = UnitInRaid("player") or IsInGroup()
            MethodDungeonTools.main_frame.LinkToChatButton:SetDisabled(not inGroup)
            MethodDungeonTools.main_frame.LiveSessionButton:SetDisabled(not inGroup)
            if inGroup then
                MethodDungeonTools.main_frame.LinkToChatButton.text:SetTextColor(1,0.8196,0)
                MethodDungeonTools.main_frame.LiveSessionButton.text:SetTextColor(1,0.8196,0)
            else
                MethodDungeonTools.main_frame.LinkToChatButton.text:SetTextColor(0.5,0.5,0.5)
                MethodDungeonTools.main_frame.LiveSessionButton.text:SetTextColor(0.5,0.5,0.5)
            end
            last = now
        end
    end
    function MethodDungeonTools.PLAYER_ENTERING_WORLD(self,addon)
        MethodDungeonTools:GetCurrentAffixWeek()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

end


MethodDungeonTools.mapInfo = {}
MethodDungeonTools.dungeonTotalCount = {}
MethodDungeonTools.scaleMultiplier = {}

local affixWeeks = { --affixID as used in C_ChallengeMode.GetAffixInfo(affixID)
    [1] = {[1]=5,[2]=3,[3]=9,[4]=120},
    [2] = {[1]=7,[2]=2,[3]=10,[4]=120},
    [3] = {[1]=11,[2]=4,[3]=9,[4]=120},
    [4] = {[1]=8,[2]=14,[3]=10,[4]=120},
    [5] = {[1]=7,[2]=13,[3]=9,[4]=120},
    [6] = {[1]=11,[2]=3,[3]=10,[4]=120},
    [7] = {[1]=6,[2]=4,[3]=9,[4]=120},
    [8] = {[1]=5,[2]=14,[3]=10,[4]=120},
    [9] = {[1]=11,[2]=2,[3]=9,[4]=120},
    [10] = {[1]=7,[2]=12,[3]=10,[4]=120},
    [11] = {[1]=6,[2]=13,[3]=9,[4]=120},
    [12] = {[1]=8,[2]=12,[3]=10,[4]=120},
}

local dungeonList = {
    [1] = "Black Rook Hold",
    [2] = "Cathedral of Eternal Night",
    [3] = "Court of Stars",
    [4] = "Darkheart Thicket",
    [5] = "Eye of Azshara",
    [6] = "Halls of Valor",
    [7] = "Maw of Souls",
    [8] = "Neltharion's Lair",
    [9] = "Return to Karazhan Lower",
    [10] = "Return to Karazhan Upper",
    [11] = "Seat of the Triumvirate",
    [12] = "The Arcway",
    [13] = "Vault of the Wardens",
    [14] = " >Battle for Azeroth",
    [15] = "Atal'Dazar",
    [16] = "Freehold",
    [17] = "Kings' Rest",
    [18] = "Shrine of the Storm",
    [19] = "Siege of Boralus",
    [20] = "Temple of Sethraliss",
    [21] = "The MOTHERLODE!!",
    [22] = "The Underrot",
    [23] = "Tol Dagor",
    [24] = "Waycrest Manor",
    [25] = "Mechagon - Junkyard",
    [26] = "Mechagon - Workshop",
    [27] = " >Legion",
}
function MethodDungeonTools:GetNumDungeons() return #dungeonList-1 end
function MethodDungeonTools:GetDungeonName(idx) return dungeonList[idx] end

local dungeonSubLevels = {
    [1] = {
        [1] = "The Ravenscrypt",
        [2] = "The Grand Hall",
        [3] = "Ravenshold",
        [4] = "The Rook's Host",
        [5] = "Lord Ravencrest's Chamber",
        [6] = "The Raven's Crown",
    },
    [2] = {
        [1] = "Hall of the Moon",
        [2] = "Twilight Grove",
        [3] = "The Emerald Archives",
        [4] = "Path of Illumination",
        [5] = "Sacristy of Elune",
    },
    [3] = {
        [1] = "Court of Stars",
        [2] = "The Jeweled Estate",
        [3] = "The Balconies",
    },
    [4] = {
        [1] = "Darkheart Thicket",
    },
    [5] = {
        [1] = "Eye of Azshara",
    },
    [6] = {
        [1] = "The High Gate",
        [2] = "Field of the Eternal Hunt",
        [3] = "Halls of Valor",
    },
    [7] = {
        [1] = "Helmouth Cliffs",
        [2] = "The Hold",
        [3] = "The Naglfar",
    },
    [8] = {
        [1] = "Neltharion's Lair",
    },
    [9] = {
        [1] = "Master's Terrace",
        [2] = "Opera Hall Balcony",
        [3] = "The Guest Chambers",
        [4] = "The Banquet Hall",
        [5] = "Upper Livery Stables",
        [6] = "The Servant's Quarters",
    },
    [10] = {
        [1] = "Lower Broken Stair",
        [2] = "Upper Broken Stair",
        [3] = "The Menagerie",
        [4] = "Guardian's Library",
        [5] = "Library Floor",
        [6] = "Upper Library",
        [7] = "Gamesman's Hall",
        [8] = "Netherspace",
    },
    [11] = {
        [1] = "Seat of the Triumvirate",
    },
    [12] = {
        [1] = "The Arcway",
    },
    [13] = {
        [1] = "The Warden's Court",
        [2] = "Vault of the Wardens",
        [3] = "Vault of the Betrayer",
    },
    [15] = {
        [1] = "Atal'Dazar",
        [2] = "Sacrificial Pits",
    },
    [16] = {
        [1] = "Freehold",
    },
    [17] = {
        [1] = "Kings' Rest",
    },
    [18] = {
        [1] = "Shrine of the Storm",
        [2] = "Storm's End",
    },
    [19] = {
        [1] = "Siege of Boralus",
        [2] = "Siege of Boralus (Upstairs)",
    },
    [20] = {
        [1] = "Temple of Sethraliss",
        [2] = "Atrium of Sethraliss",
    },
    [21] = {
        [1] = "The MOTHERLODE!!",
    },
    [22] = {
        [1] = "The Underrot",
        [2] = "Ruin's Descent",
    },
    [23] = {
        [1] = "Tol Dagor",
        [2] = "The Drain",
        [3] = "The Brig",
        [4] = "Detention Block",
        [5] = "Officer Quarters",
        [6] = "Overseer's Redoubt",
        [7] = "Overseer's Summit",
    },
    [24] = {
        [1] = "The Grand Foyer",
        [2] = "Upstairs",
        [3] = "The Cellar",
        [4] = "Catacombs",
        [5] = "The Rupture",
    },
    [25] = {
        [1] = "Mechagon Island",
        [2] = "Mechagon Island (Tunnels)",
    },
    [26] = {
        [1] = "The Robodrome",
        [2] = "Waste Pipes",
        [3] = "The Under Junk",
        [4] = "Mechagon City",
    },
}
if _G["MDT_DungeonSubLevels_"..GetLocale()] then dungeonSubLevels = _G["MDT_DungeonSubLevels_"..GetLocale()] end
function MethodDungeonTools:GetDungeonSublevels()
    return dungeonSubLevels
end

function MethodDungeonTools:GetSublevelName(dungeonIdx,sublevelIdx)
    if not dungeonIdx then dungeonIdx = db.currentDungeonIdx end
    return dungeonSubLevels[dungeonIdx][sublevelIdx]
end

MethodDungeonTools.dungeonMaps = {
	[1] = {
		[0]= "BlackRookHoldDungeon",
		[1]= "BlackRookHoldDungeon1_",
		[2]= "BlackRookHoldDungeon2_",
		[3]= "BlackRookHoldDungeon3_",
		[4]= "BlackRookHoldDungeon4_",
		[5]= "BlackRookHoldDungeon5_",
		[6]= "BlackRookHoldDungeon6_",
	},
	[2] = {
		[0]= "TombofSargerasDungeon",
		[1]= "TombofSargerasDungeon1_",
		[2]= "TombofSargerasDungeon2_",
		[3]= "TombofSargerasDungeon3_",
		[4]= "TombofSargerasDungeon4_",
		[5]= "TombofSargerasDungeon5_",
	},
	[3] = {
		[0] = "SuramarNoblesDistrict",
		[1] = "SuramarNoblesDistrict",
		[2] = "SuramarNoblesDistrict1_",
		[3] = "SuramarNoblesDistrict2_",
	},
	[4] = {
		[0] = "DarkheartThicket",
		[1] = "DarkheartThicket",
	},
	[5] = {
		[0]= "AszunaDungeon",
		[1]= "AszunaDungeon",
	},
	[6] = {
		[0]= "Hallsofvalor",
		[1]= "Hallsofvalor1_",
		[2]= "Hallsofvalor",
		[3]= "Hallsofvalor2_",
	},

	[7] = {
		[0] = "HelheimDungeonDock",
		[1] = "HelheimDungeonDock",
		[2] = "HelheimDungeonDock1_",
		[3] = "HelheimDungeonDock2_",
	},
	[8] = {
		[0] = "NeltharionsLair",
		[1] = "NeltharionsLair",
	},
	[9] = {
		[0] = "LegionKarazhanDungeon",
		[1] = "LegionKarazhanDungeon6_",
		[2] = "LegionKarazhanDungeon5_",
		[3] = "LegionKarazhanDungeon4_",
		[4] = "LegionKarazhanDungeon3_",
		[5] = "LegionKarazhanDungeon2_",
		[6] = "LegionKarazhanDungeon1_",
	},
	[10] = {
		[0] = "LegionKarazhanDungeon",
		[1] = "LegionKarazhanDungeon7_",
		[2] = "LegionKarazhanDungeon8_",
		[3] = "LegionKarazhanDungeon9_",
		[4] = "LegionKarazhanDungeon10_",
		[5] = "LegionKarazhanDungeon11_",
		[6] = "LegionKarazhanDungeon12_",
		[7] = "LegionKarazhanDungeon13_",
		[8] = "LegionKarazhanDungeon14_",
	},
	[11] = {
		[0] = "ArgusDungeon",
		[1] = "ArgusDungeon",
	},
	[12] = {
		[0]= "SuamarCatacombsDungeon",
		[1]= "SuamarCatacombsDungeon1_",
	},
	[13] = {
		[0]= "VaultOfTheWardens",
		[1]= "VaultOfTheWardens1_",
		[2]= "VaultOfTheWardens2_",
		[3]= "VaultOfTheWardens3_",
	},
	[15] = {
		[0]= "CityOfGold",
		[1]= "CityOfGold1_",
		[2]= "CityOfGold2_",
	},
	[16] = {
		[0]= "KulTirasPirateTownDungeon",
		[1]= "KulTirasPirateTownDungeon",
	},
	[17] = {
        [0] = "KingsRest",
        [1] = "KingsRest1_"
	},
    [18] = {
        [0] = "ShrineOfTheStorm",
        [1] = "ShrineOfTheStorm",
        [2] = "ShrineOfTheStorm1_",
    },
    [19] = {
        [0] = "SiegeOfBoralus",
        [1] = "SiegeOfBoralus",
        [2] = "SiegeOfBoralus",
    },
    [20] = {
        [0] = "TempleOfSethralissA",
        [1] = "TempleOfSethralissA",
        [2] = "TempleOfSethralissB",
    },
    [21] = {
        [0] = "KezanDungeon",
        [1] = "KezanDungeon",
    },
    [22] = {
        [0] = "UnderrotExterior",
        [1] = "UnderrotExterior",
        [2] = "UnderrotInterior",
    },
    [23] = {
        [0] = "PrisonDungeon",
        [1] = "PrisonDungeon",
        [2] = "PrisonDungeon1_",
        [3] = "PrisonDungeon2_",
        [4] = "PrisonDungeon3_",
        [5] = "PrisonDungeon4_",
        [6] = "PrisonDungeon5_",
        [7] = "PrisonDungeon6_",
    },
    [24] = {
        [0] = "Waycrest",
        [1] = "Waycrest1_",
        [2] = "Waycrest2_",
        [3] = "Waycrest3_",
        [4] = "Waycrest4_",
        [5] = "Waycrest5_",
    },
    [25] = {
        [0] = "MechagonDungeon",
        [1] = "MechagonDungeonExterior",
        [2] = "MechagonDungeonExterior",
    },
    [26] = {
        [0] = "MechagonDungeon",
        [1] = "MechagonDungeon1_",
        [2] = "MechagonDungeon2_",
        [3] = "MechagonDungeon3_",
        [4] = "MechagonDungeon4_",
    },

}
MethodDungeonTools.dungeonBosses = {}
MethodDungeonTools.dungeonEnemies = {}
MethodDungeonTools.mapPOIs = {}

function MethodDungeonTools:GetDB()
    return db
end

local framesInitialized
function MethodDungeonTools:ShowInterface(force)
    if not framesInitialized then initFrames() end
	if self.main_frame:IsShown() and not force then
		MethodDungeonTools:HideInterface()
	else
		self.main_frame:Show()
		self.main_frame.HelpButton:Show()
        self:CheckCurrentZone()
        --edge case if user closed MDT window while in the process of dragging a corrupted blip
        if self.draggedBlip then
            if MethodDungeonTools.liveSessionActive then
                MethodDungeonTools:LiveSession_SendCorruptedPositions(MethodDungeonTools:GetRiftOffsets())
            end
            self:UpdateMap()
            self.draggedBlip = nil
        end
	end
end

function MethodDungeonTools:HideInterface()
	self.main_frame:Hide()
	self.main_frame.HelpButton:Hide()
end

function MethodDungeonTools:ToggleDevMode()
    db.devMode = not db.devMode
    ReloadUI()
end

function MethodDungeonTools:ToggleDataCollection()
    db.dataCollectionActive = not db.dataCollectionActive
    print(string.format("%sMDT|r: DataCollection %s. Reload Interface!",methodColor,db.dataCollectionActive and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
end

function MethodDungeonTools:ToggleHealthTrack()
    MethodDungeonTools.DataCollection:InitHealthTrack()
    print(string.format("%sMDT|r: HealthTrack %s.",methodColor,"|cFF00FF00Enabled|r"))
end


function MethodDungeonTools:CreateMenu()
    -- Close button
    self.main_frame.closeButton = CreateFrame("Button", "MDTCloseButton", self.main_frame, "UIPanelCloseButton")
    self.main_frame.closeButton:ClearAllPoints()
    self.main_frame.closeButton:SetPoint("TOPRIGHT", self.main_frame.sidePanel, "TOPRIGHT", 0, 0)
    self.main_frame.closeButton:SetScript("OnClick", function() self:HideInterface() end)
    self.main_frame.closeButton:SetFrameLevel(4)

    --Maximize Button
    self.main_frame.maximizeButton = CreateFrame("Button", "MDTMaximizeButton", self.main_frame, "MaximizeMinimizeButtonFrameTemplate")
    self.main_frame.maximizeButton:ClearAllPoints()
    self.main_frame.maximizeButton:SetPoint("RIGHT", self.main_frame.closeButton, "LEFT", 0, 0)
    self.main_frame.maximizeButton:SetFrameLevel(4)
    db.maximized = db.maximized or false
    if not db.maximized then self.main_frame.maximizeButton:Minimize() end
    self.main_frame.maximizeButton:SetOnMaximizedCallback(self.Maximize)
    self.main_frame.maximizeButton:SetOnMinimizedCallback(self.Minimize)

    --return to live preset
    self.main_frame.liveReturnButton = CreateFrame("Button", "MDTLiveReturnButton", self.main_frame, "BrowserButtonTemplate")
    local liveReturnButton = self.main_frame.liveReturnButton
    liveReturnButton:ClearAllPoints()
    liveReturnButton:SetPoint("RIGHT", self.main_frame.topPanel, "RIGHT", 0, 0)
    liveReturnButton.Icon = liveReturnButton:CreateTexture(nil, "OVERLAY")
    liveReturnButton.Icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    liveReturnButton.Icon:SetSize(16,16)
    liveReturnButton.Icon:SetTexCoord(1, 0, 0, 1) --flipped image
    liveReturnButton.Icon:SetPoint("CENTER",liveReturnButton,"CENTER")
    liveReturnButton:SetScript("OnClick", function() self:ReturnToLivePreset() end)
    liveReturnButton:SetFrameLevel(4)
    liveReturnButton.tooltip = "Return to the live preset"

    --set preset as new live preset
    self.main_frame.setLivePresetButton = CreateFrame("Button", "MDTSetLivePresetButton", self.main_frame, "BrowserButtonTemplate")
    local setLivePresetButton = self.main_frame.setLivePresetButton
    setLivePresetButton:ClearAllPoints()
    setLivePresetButton:SetPoint("RIGHT", liveReturnButton, "LEFT", 0, 0)
    setLivePresetButton.Icon = setLivePresetButton:CreateTexture(nil, "OVERLAY")
    setLivePresetButton.Icon:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    setLivePresetButton.Icon:SetSize(16,16)
    setLivePresetButton.Icon:SetPoint("CENTER",setLivePresetButton,"CENTER")
    setLivePresetButton:SetScript("OnClick", function() self:SetLivePreset() end)
    setLivePresetButton:SetFrameLevel(4)
    setLivePresetButton.tooltip = "Make this preset the live preset"

    self:SkinMenuButtons()

    --Resize Handle
    self.main_frame.resizer = CreateFrame("BUTTON", nil, self.main_frame.sidePanel)
    local resizer = self.main_frame.resizer
    resizer:SetPoint("BOTTOMRIGHT", self.main_frame.sidePanel,"BOTTOMRIGHT",7,-7)
    resizer:SetSize(25, 25)
    resizer:EnableMouse()
    resizer:SetScript("OnMouseDown", function()
        self.main_frame:StartSizing("BOTTOMRIGHT")
        self:StartScaling()
        self:HideAllPresetObjects()
        self.main_frame:SetScript("OnSizeChanged", function()
            local height = self.main_frame:GetHeight()
            self:SetScale(height/sizey)
        end)
    end)
    resizer:SetScript("OnMouseUp", function()
        self.main_frame:StopMovingOrSizing()
        self:UpdateEnemyInfoFrame()
        self:UpdateMap()
        self:CreateTutorialButton(self.main_frame)
        self.main_frame:SetScript("OnSizeChanged", function() end)
    end)
    local normal = resizer:CreateTexture(nil, "OVERLAY")
    normal:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    normal:SetTexCoord(0, 1, 0, 1)
    normal:SetPoint("BOTTOMLEFT", resizer, 0, 6)
    normal:SetPoint("TOPRIGHT", resizer, -6, 0)
    resizer:SetNormalTexture(normal)
    local pushed = resizer:CreateTexture(nil, "OVERLAY")
    pushed:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    pushed:SetTexCoord(0, 1, 0, 1)
    pushed:SetPoint("BOTTOMLEFT", resizer, 0, 6)
    pushed:SetPoint("TOPRIGHT", resizer, -6, 0)
    resizer:SetPushedTexture(pushed)
    local highlight = resizer:CreateTexture(nil, "OVERLAY")
    highlight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    highlight:SetTexCoord(0, 1, 0, 1)
    highlight:SetPoint("BOTTOMLEFT", resizer, 0, 6)
    highlight:SetPoint("TOPRIGHT", resizer, -6, 0)
    resizer:SetHighlightTexture(highlight)

end

function MethodDungeonTools:SkinMenuButtons()
    --attempt to skin close button for ElvUI
    if IsAddOnLoaded("ElvUI") then
    local E, L, V, P, G = unpack(ElvUI)
    local S
    if E then S = E:GetModule("Skins") end
        if S then
            S:HandleCloseButton(self.main_frame.closeButton)
            S:HandleMaxMinFrame(self.main_frame.maximizeButton)
            S:HandleButton(self.main_frame.liveReturnButton)
            self.main_frame.liveReturnButton:Size(26)
            --self.main_frame.liveReturnButton.Icon:SetVertexColor(0,1,1,1)
            S:HandleButton(self.main_frame.setLivePresetButton)
            self.main_frame.setLivePresetButton:Size(26)
            self.main_frame.setLivePresetButton.Icon:SetVertexColor(1, .82, 0, 0.8)
        end
    end
end

---GetDefaultMapPanelSize
function MethodDungeonTools:GetDefaultMapPanelSize()
    return sizex,sizey
end

---GetScale
---Returns scale factor stored in db
function MethodDungeonTools:GetScale()
    if not db.scale then db.scale = 1 end
    return db.scale
end


local oldScrollValues = {}
---StartScaling
---Stores values when we start scaling the frame
function MethodDungeonTools:StartScaling()
    local f = self.main_frame
    oldScrollValues.oldScrollH = f.scrollFrame:GetHorizontalScroll()
    oldScrollValues.oldScrollV = f.scrollFrame:GetVerticalScroll()
    oldScrollValues.oldSizeX = f.scrollFrame:GetWidth()
    oldScrollValues.oldSizeY = f.scrollFrame:GetHeight()
    HelpPlate_Hide(true)
    self:DungeonEnemies_HideAllBlips()
    self:POI_HideAllPoints()
    self:KillAllAnimatedLines()
end


---SetScale
---Scales the map frame and it's sub frames to a factor and stores the scale in db
function MethodDungeonTools:SetScale(scale)
    local f = self.main_frame
    local newSizex = sizex*scale
    local newSizey = sizey*scale
    f:SetSize(newSizex,newSizey)
    f.scrollFrame:SetSize(newSizex, newSizey)
    f.mapPanelFrame:SetSize(newSizex, newSizey)
    for i=1,12 do
        f["mapPanelTile"..i]:SetSize((newSizex/4+5*scale),(newSizex/4+5*scale))
    end
    for i=1,10 do
        for j=1,15 do
            f["largeMapPanelTile"..i..j]:SetSize(newSizex/15,newSizex/15)
        end
    end
    f.scrollFrame:SetVerticalScroll(oldScrollValues.oldScrollV * (newSizey / oldScrollValues.oldSizeY))
    f.scrollFrame:SetHorizontalScroll(oldScrollValues.oldScrollH * (newSizex / oldScrollValues.oldSizeX))
    f.scrollFrame.cursorY = f.scrollFrame.cursorY * (newSizey / oldScrollValues.oldSizeY)
    f.scrollFrame.cursorX = f.scrollFrame.cursorX * (newSizex / oldScrollValues.oldSizeX)
    self:ZoomMap(0)
    db.scale = scale
    db.nonFullscreenScale = scale
end

function MethodDungeonTools:GetFullScreenSizes()
    local newSizey = GetScreenHeight()-60 --top and bottom panel 30 each
    local newSizex = newSizey*(sizex/sizey)
    local isNarrow
    if newSizex+251>GetScreenWidth() then --251 sidebar
        newSizex = GetScreenWidth()-251
        newSizey = newSizex*(sizey/sizex)
        isNarrow = true
    end
    local scale = newSizey/sizey --use this for adjusting NPC / POI positions later
    return newSizex, newSizey, scale, isNarrow
end

---Maximize
---FULLSCREEN the UI
function MethodDungeonTools:Maximize()
    local f = MethodDungeonTools.main_frame

    local oldScrollH = f.scrollFrame:GetHorizontalScroll()
    local oldScrollV = f.scrollFrame:GetVerticalScroll()
    local oldSizeX = f.scrollFrame:GetWidth()
    local oldSizeY = f.scrollFrame:GetHeight()
    if not f.blackoutFrame then
        f.blackoutFrame = CreateFrame("Frame", "MethodDungeonToolsBlackoutFrame", f)
        f.blackoutFrame:EnableMouse(true)
        f.blackoutFrameTex = f.blackoutFrame:CreateTexture(nil, "BACKGROUND")
        f.blackoutFrameTex:SetAllPoints()
        f.blackoutFrameTex:SetDrawLayer(canvasDrawLayer, -6)
        f.blackoutFrameTex:SetColorTexture(0.058823399245739,0.058823399245739,0.058823399245739,1)
        f.blackoutFrame:ClearAllPoints()
        f.blackoutFrame:SetAllPoints(UIParent)
    end
    f.blackoutFrame:Show()
    f.topPanel:RegisterForDrag(nil)
    f.bottomPanel:RegisterForDrag(nil)
    local newSizex, newSizey, scale, isNarrow = MethodDungeonTools:GetFullScreenSizes()
    db.scale = scale
    f:ClearAllPoints()
    if not isNarrow then
        f:SetPoint("TOP", UIParent,"TOP", -(f.sidePanel:GetWidth()/2), -30)
    else
        f:SetPoint("LEFT", UIParent,"LEFT")
    end
    f:SetSize(newSizex,newSizey)
    f.scrollFrame:SetSize(newSizex, newSizey)
    f.mapPanelFrame:SetSize(newSizex, newSizey)
    for i=1,12 do
        f["mapPanelTile"..i]:SetSize((newSizex/4+5*db.scale),(newSizex/4+5*db.scale))
    end
    for i=1,10 do
        for j=1,15 do
            f["largeMapPanelTile"..i..j]:SetSize(newSizex/15,newSizex/15)
        end
    end
    f.scrollFrame:SetVerticalScroll(oldScrollV * (newSizey / oldSizeY))
    f.scrollFrame:SetHorizontalScroll(oldScrollH * (newSizex / oldSizeX))
    f.scrollFrame.cursorY = f.scrollFrame.cursorY * (newSizey / oldSizeY)
    f.scrollFrame.cursorX = f.scrollFrame.cursorX * (newSizex / oldSizeX)
    MethodDungeonTools:ZoomMap(0)
    MethodDungeonTools:UpdateEnemyInfoFrame()
    MethodDungeonTools:UpdateMap()
    if db.devMode then
        f.devPanel:ClearAllPoints()
        f.devPanel:SetPoint("TOPLEFT",f,"TOPLEFT",0,-45)
    end
    f.resizer:Hide()
    MethodDungeonTools:CreateTutorialButton(MethodDungeonTools.main_frame)
    db.maximized = true
end

---Minimize
---Restore normal UI
function MethodDungeonTools:Minimize()
    local f = MethodDungeonTools.main_frame

    local oldScrollH = f.scrollFrame:GetHorizontalScroll()
    local oldScrollV = f.scrollFrame:GetVerticalScroll()
    local oldSizeX = f.scrollFrame:GetWidth()
    local oldSizeY = f.scrollFrame:GetHeight()
    if f.blackoutFrame then f.blackoutFrame:Hide() end
    f.topPanel:RegisterForDrag("LeftButton")
    f.bottomPanel:RegisterForDrag("LeftButton")
    db.scale = db.nonFullscreenScale
    local newSizex = sizex*db.scale
    local newSizey = sizey*db.scale
    f:ClearAllPoints()
    f:SetPoint(db.anchorTo, UIParent,db.anchorFrom, db.xoffset, db.yoffset)
    f:SetSize(newSizex,newSizey)
    f.scrollFrame:SetSize(newSizex, newSizey)
    f.mapPanelFrame:SetSize(newSizex, newSizey)
    for i=1,12 do
        f["mapPanelTile"..i]:SetSize(newSizex/4+(5*db.scale),newSizex/4+(5*db.scale))
    end
    for i=1,10 do
        for j=1,15 do
            f["largeMapPanelTile"..i..j]:SetSize(newSizex/15,newSizex/15)
        end
    end
    f.scrollFrame:SetVerticalScroll(oldScrollV * (newSizey / oldSizeY))
    f.scrollFrame:SetHorizontalScroll(oldScrollH * (newSizex / oldSizeX))
    f.scrollFrame.cursorY = f.scrollFrame.cursorY * (newSizey / oldSizeY)
    f.scrollFrame.cursorX = f.scrollFrame.cursorX * (newSizex / oldSizeX)
    MethodDungeonTools:ZoomMap(0)
    MethodDungeonTools:UpdateEnemyInfoFrame()
    MethodDungeonTools:UpdateMap()
    if db.devMode then
        f.devPanel:ClearAllPoints()
        f.devPanel:SetPoint("TOPRIGHT",f.topPanel,"TOPLEFT",0,0)
    end
    f.resizer:Show()
    MethodDungeonTools:CreateTutorialButton(MethodDungeonTools.main_frame)

    db.maximized = false
end

function MethodDungeonTools:SkinProgressBar(progressBar)
    local bar = progressBar and progressBar.Bar
    if not bar then return end
    bar.Icon:Hide()
    bar.IconBG:Hide()
    if IsAddOnLoaded("ElvUI") then
        local E, L, V, P, G = unpack(ElvUI)
        if bar.BarFrame then bar.BarFrame:Hide() end
        if bar.BarFrame2 then bar.BarFrame2:Hide() end
        if bar.BarFrame3 then bar.BarFrame3:Hide() end
        if bar.BarGlow then bar.BarGlow:Hide() end
        if bar.Sheen then bar.Sheen:Hide() end
        if bar.IconBG then bar.IconBG:SetAlpha(0) end
        if bar.BorderLeft then bar.BorderLeft:SetAlpha(0) end
        if bar.BorderRight then bar.BorderRight:SetAlpha(0) end
        if bar.BorderMid then bar.BorderMid:SetAlpha(0) end
        bar:Height(18)
        bar:StripTextures()
        bar:CreateBackdrop("Transparent")
        bar:SetStatusBarTexture(E.media.normTex)
        local label = bar.Label
        if not label then return end
        label:ClearAllPoints()
        label:SetPoint("CENTER",bar,"CENTER")
    end
end

function MethodDungeonTools:IsFrameOffScreen()
    local topPanel = MethodDungeonTools.main_frame.topPanel
    local bottomPanel = MethodDungeonTools.main_frame.bottomPanel
    local width = GetScreenWidth()
    local height = GetScreenHeight()
    local left = topPanel:GetLeft()-->width
    local right = topPanel:GetRight()--<0
    local bottom = topPanel:GetBottom()--<0
    local top = bottomPanel:GetTop()-->height
    return left>width or right<0 or bottom<0 or top>height
end

function MethodDungeonTools:MakeTopBottomTextures(frame)
    frame:SetMovable(true)
	if frame.topPanel == nil then
		frame.topPanel = CreateFrame("Frame", "MethodDungeonToolsTopPanel", frame)
		frame.topPanelTex = frame.topPanel:CreateTexture(nil, "BACKGROUND")
		frame.topPanelTex:SetAllPoints()
		frame.topPanelTex:SetDrawLayer(canvasDrawLayer, -5)
		frame.topPanelTex:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))
		frame.topPanelString = frame.topPanel:CreateFontString("MethodDungeonTools name")
		--use default font if ElvUI is enabled
		--if IsAddOnLoaded("ElvUI") then
        frame.topPanelString:SetFontObject("GameFontNormalMed3")
		frame.topPanelString:SetTextColor(1, 1, 1, 1)
		frame.topPanelString:SetJustifyH("CENTER")
		frame.topPanelString:SetJustifyV("CENTER")
		--frame.topPanelString:SetWidth(600)
		frame.topPanelString:SetHeight(20)
		frame.topPanelString:SetText("Method Dungeon Tools")
		frame.topPanelString:ClearAllPoints()
		frame.topPanelString:SetPoint("CENTER", frame.topPanel, "CENTER", 0, 0)
		frame.topPanelString:Show()
        --frame.topPanelString:SetFont(frame.topPanelString:GetFont(), 20)
		frame.topPanelLogo = frame.topPanel:CreateTexture(nil, "HIGH", nil, 7)
		frame.topPanelLogo:SetTexture("Interface\\AddOns\\MethodDungeonTools\\Textures\\Method")
		frame.topPanelLogo:SetWidth(24)
		frame.topPanelLogo:SetHeight(24)
		frame.topPanelLogo:SetPoint("RIGHT",frame.topPanelString,"LEFT",-5,0)
		frame.topPanelLogo:Show()
	end

    frame.topPanel:ClearAllPoints()
    frame.topPanel:SetHeight(30)
    frame.topPanel:SetPoint("BOTTOMLEFT", frame, "TOPLEFT")
    frame.topPanel:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT")

    frame.topPanel:EnableMouse(true)
    frame.topPanel:RegisterForDrag("LeftButton")
    frame.topPanel:SetScript("OnDragStart", function(self,button)
        frame:SetMovable(true)
        frame:StartMoving()
    end)
    frame.topPanel:SetScript("OnDragStop", function(self,button)
        frame:StopMovingOrSizing()
        frame:SetMovable(false)
        if MethodDungeonTools:IsFrameOffScreen() then
            MethodDungeonTools:ResetMainFramePos(true)
        else
            local from,_,to,x,y = MethodDungeonTools.main_frame:GetPoint()
            db.anchorFrom = from
            db.anchorTo = to
            db.xoffset,db.yoffset = x,y
        end
    end)

    if frame.bottomPanel == nil then
        frame.bottomPanel = CreateFrame("Frame", "MethodDungeonToolsBottomPanel", frame)
        frame.bottomPanelTex = frame.bottomPanel:CreateTexture(nil, "BACKGROUND")
        frame.bottomPanelTex:SetAllPoints()
        frame.bottomPanelTex:SetDrawLayer(canvasDrawLayer, -5)
        frame.bottomPanelTex:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))
    end

    frame.bottomPanel:ClearAllPoints()
    frame.bottomPanel:SetHeight(30)
    frame.bottomPanel:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
    frame.bottomPanel:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT")

    frame.bottomPanelString = frame.bottomPanel:CreateFontString("MethodDungeonTools Version")
    frame.bottomPanelString:SetFontObject("GameFontNormalSmall")
    frame.bottomPanelString:SetJustifyH("CENTER")
    frame.bottomPanelString:SetJustifyV("CENTER")
	frame.bottomPanelString:SetText("v"..GetAddOnMetadata(AddonName, "Version"))--.." - Please report missing/wrongly positioned NPCs in discord.gg/nnogga or on github.com/nnogga/MethodDungeonTools"
	frame.bottomPanelString:SetPoint("CENTER", frame.bottomPanel, "CENTER", 0, 0)
	frame.bottomPanelString:SetTextColor(1, 1, 1, 1)
	frame.bottomPanelString:Show()

	frame.bottomPanel:EnableMouse(true)
	frame.bottomPanel:RegisterForDrag("LeftButton")
	frame.bottomPanel:SetScript("OnDragStart", function(self,button)
		frame:SetMovable(true)
        frame:StartMoving()
    end)
	frame.bottomPanel:SetScript("OnDragStop", function(self,button)
        frame:StopMovingOrSizing()
		frame:SetMovable(false)
        if MethodDungeonTools:IsFrameOffScreen() then
            MethodDungeonTools:ResetMainFramePos(true)
        else
            local from,_,to,x,y = MethodDungeonTools.main_frame:GetPoint()
            db.anchorFrom = from
            db.anchorTo = to
            db.xoffset,db.yoffset = x,y
        end
    end)
end

function MethodDungeonTools:MakeSidePanel(frame)

	if frame.sidePanel == nil then
		frame.sidePanel = CreateFrame("Frame", "MethodDungeonToolsSidePanel", frame)
		frame.sidePanelTex = frame.sidePanel:CreateTexture(nil, "BACKGROUND")
		frame.sidePanelTex:SetAllPoints()
		frame.sidePanelTex:SetDrawLayer(canvasDrawLayer, -5)
		frame.sidePanelTex:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))
		frame.sidePanelTex:Show()
	end
    frame.sidePanel:EnableMouse(true)

	frame.sidePanel:ClearAllPoints()
	frame.sidePanel:SetWidth(251)
	frame.sidePanel:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 30)
	frame.sidePanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 0, -30)

	frame.sidePanelString = frame.sidePanel:CreateFontString("MethodDungeonToolsSidePanelText")
	frame.sidePanelString:SetFont("Fonts\\FRIZQT__.TTF", 10)
	frame.sidePanelString:SetTextColor(1, 1, 1, 1)
	frame.sidePanelString:SetJustifyH("LEFT")
	frame.sidePanelString:SetJustifyV("TOP")
	frame.sidePanelString:SetWidth(200)
	frame.sidePanelString:SetHeight(500)
	frame.sidePanelString:SetText("")
	frame.sidePanelString:ClearAllPoints()
	frame.sidePanelString:SetPoint("TOPLEFT", frame.sidePanel, "TOPLEFT", 33, -120-30-25)
	frame.sidePanelString:Hide()

	frame.sidePanel.WidgetGroup = AceGUI:Create("SimpleGroup")
	frame.sidePanel.WidgetGroup:SetWidth(245)
	frame.sidePanel.WidgetGroup:SetHeight(frame:GetHeight()+(frame.topPanel:GetHeight()*2)-31)
	frame.sidePanel.WidgetGroup:SetPoint("TOP",frame.sidePanel,"TOP",3,-1)
	frame.sidePanel.WidgetGroup:SetLayout("Flow")

	frame.sidePanel.WidgetGroup.frame:SetFrameStrata(mainFrameStrata)
	frame.sidePanel.WidgetGroup.frame:SetBackdropColor(1,1,1,0)
	frame.sidePanel.WidgetGroup.frame:Hide()

	--dirty hook to make widgetgroup show/hide
	local originalShow,originalHide = frame.Show,frame.Hide
	function frame:Show(...)
		frame.sidePanel.WidgetGroup.frame:Show()
		return originalShow(self, ...)
	end
	function frame:Hide(...)
		frame.sidePanel.WidgetGroup.frame:Hide()
        MethodDungeonTools.pullTooltip:Hide()
		return originalHide(self, ...)
	end

	--preset selection
	frame.sidePanel.WidgetGroup.PresetDropDown = AceGUI:Create("Dropdown")
	local dropdown = frame.sidePanel.WidgetGroup.PresetDropDown
    dropdown.frame:SetWidth(170)
	dropdown.text:SetJustifyH("LEFT")
	dropdown:SetCallback("OnValueChanged",function(widget,callbackName,key)
		if db.presets[db.currentDungeonIdx][key].value==0 then
			MethodDungeonTools:OpenNewPresetDialog()
			MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(true)
			MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(0.5,0.5,0.5)
		else
			if key == 1 then
				MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(true)
                MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(0.5,0.5,0.5)
			else
                if not MethodDungeonTools.liveSessionActive then
                    MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
                    MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(1,0.8196,0)
                else
                    MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(true)
                    MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(0.5,0.5,0.5)
                end
			end
			db.currentPreset[db.currentDungeonIdx] = key
            --Set affix dropdown to preset week
            --frame.sidePanel.affixDropdown:SetAffixWeek(MethodDungeonTools:GetCurrentPreset().week or MethodDungeonTools:GetCurrentAffixWeek())
			--UpdateMap is called in SetAffixWeek, no need to call twice
            MethodDungeonTools:UpdateMap()
            frame.sidePanel.affixDropdown:SetAffixWeek(MethodDungeonTools:GetCurrentPreset().week or MethodDungeonTools:GetCurrentAffixWeek() or 1)
		end
	end)
	MethodDungeonTools:UpdatePresetDropDown()
	frame.sidePanel.WidgetGroup:AddChild(dropdown)

	---new profile,rename,export,delete
	local buttonWidth = 80
	frame.sidePanelNewButton = AceGUI:Create("Button")
	frame.sidePanelNewButton:SetText(L"New")
	frame.sidePanelNewButton:SetWidth(buttonWidth)
	--button fontInstance
	local fontInstance = CreateFont("MDTButtonFont")
	fontInstance:CopyFontObject(frame.sidePanelNewButton.frame:GetNormalFontObject())
	local fontName,height = fontInstance:GetFont()
	fontInstance:SetFont(fontName,10)
	frame.sidePanelNewButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelNewButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelNewButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelNewButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:OpenNewPresetDialog()
	end)
    frame.sidePanelNewButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.sidePanelNewButton.frame, "ANCHOR_BOTTOMLEFT",frame.sidePanelNewButton.frame:GetWidth()*(-0),frame.sidePanelNewButton.frame:GetHeight())
        GameTooltip:AddLine("Create a new preset",1,1,1)
        GameTooltip:Show()
    end)
    frame.sidePanelNewButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)

	frame.sidePanelRenameButton = AceGUI:Create("Button")
	frame.sidePanelRenameButton:SetWidth(buttonWidth)
	frame.sidePanelRenameButton:SetText(L"Rename")
	frame.sidePanelRenameButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelRenameButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelRenameButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelRenameButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:HideAllDialogs()
		local currentPresetName = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text
		MethodDungeonTools.main_frame.RenameFrame:Show()
		MethodDungeonTools.main_frame.RenameFrame.RenameButton:SetDisabled(true)
		MethodDungeonTools.main_frame.RenameFrame.RenameButton.text:SetTextColor(0.5,0.5,0.5)
        MethodDungeonTools.main_frame.RenameFrame:ClearAllPoints()
		MethodDungeonTools.main_frame.RenameFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
		MethodDungeonTools.main_frame.RenameFrame.Editbox:SetText(currentPresetName)
		MethodDungeonTools.main_frame.RenameFrame.Editbox:HighlightText(0, string.len(currentPresetName))
		MethodDungeonTools.main_frame.RenameFrame.Editbox:SetFocus()
	end)
    frame.sidePanelRenameButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.sidePanelRenameButton.frame, "ANCHOR_BOTTOMLEFT",frame.sidePanelRenameButton.frame:GetWidth()*(-1),frame.sidePanelRenameButton.frame:GetHeight())
        GameTooltip:AddLine("Rename the preset",1,1,1)
        GameTooltip:Show()
    end)
    frame.sidePanelRenameButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)

	frame.sidePanelImportButton = AceGUI:Create("Button")
	frame.sidePanelImportButton:SetText(L"Import")
	frame.sidePanelImportButton:SetWidth(buttonWidth)
	frame.sidePanelImportButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelImportButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelImportButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelImportButton:SetCallback("OnClick",function(widget,callbackName,value)
		MethodDungeonTools:OpenImportPresetDialog()
	end)
    frame.sidePanelImportButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.sidePanelImportButton.frame, "ANCHOR_BOTTOMLEFT",frame.sidePanelImportButton.frame:GetWidth()*(-1),frame.sidePanelImportButton.frame:GetHeight())
        GameTooltip:AddLine("Import a preset from a text string",1,1,1)
        GameTooltip:AddLine("You can find MDT exports from other users on the wago.io website",1,1,1,1)
        GameTooltip:Show()
    end)
    frame.sidePanelImportButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)

	frame.sidePanelExportButton = AceGUI:Create("Button")
	frame.sidePanelExportButton:SetText(L"Export")
	frame.sidePanelExportButton:SetWidth(buttonWidth)
	frame.sidePanelExportButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelExportButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelExportButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelExportButton:SetCallback("OnClick",function(widget,callbackName,value)
        if db.colorPaletteInfo.forceColorBlindMode then MethodDungeonTools:ColorAllPulls(_,_,_,true) end
        local preset = MethodDungeonTools:GetCurrentPreset()
        MethodDungeonTools:SetUniqueID(preset)
        preset.mdiEnabled = db.MDI.enabled
        preset.difficulty = db.currentDifficulty
		local export = MethodDungeonTools:TableToString(preset,true,5)
		MethodDungeonTools:HideAllDialogs()
		MethodDungeonTools.main_frame.ExportFrame:Show()
        MethodDungeonTools.main_frame.ExportFrame:ClearAllPoints()
		MethodDungeonTools.main_frame.ExportFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
		MethodDungeonTools.main_frame.ExportFrameEditbox:SetText(export)
		MethodDungeonTools.main_frame.ExportFrameEditbox:HighlightText(0, string.len(export))
		MethodDungeonTools.main_frame.ExportFrameEditbox:SetFocus()
        MethodDungeonTools.main_frame.ExportFrameEditbox:SetLabel(preset.text.." "..string.len(export))
        if db.colorPaletteInfo.forceColorBlindMode then MethodDungeonTools:ColorAllPulls() end
    end)
    frame.sidePanelExportButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.sidePanelExportButton.frame, "ANCHOR_BOTTOMLEFT",frame.sidePanelExportButton.frame:GetWidth()*(-2),frame.sidePanelExportButton.frame:GetHeight())
        GameTooltip:AddLine("Export the preset as a text string",1,1,1)
        GameTooltip:AddLine("You can share MDT exports on the wago.io website",1,1,1,1)
        GameTooltip:Show()
    end)
    frame.sidePanelExportButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)

	frame.sidePanelDeleteButton = AceGUI:Create("Button")
	frame.sidePanelDeleteButton:SetText(L"Delete")
	frame.sidePanelDeleteButton:SetWidth(buttonWidth)
	frame.sidePanelDeleteButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.sidePanelDeleteButton.frame, "ANCHOR_BOTTOMLEFT",frame.sidePanelDeleteButton.frame:GetWidth()*(-2),frame.sidePanelDeleteButton.frame:GetHeight())
        GameTooltip:AddLine("Delete this preset",1,1,1)
        GameTooltip:AddLine("Shift-Click to delete all presets for this dungeon",1,1,1)
        GameTooltip:Show()
    end)
	frame.sidePanelDeleteButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)
	frame.sidePanelDeleteButton.frame:SetNormalFontObject(fontInstance)
	frame.sidePanelDeleteButton.frame:SetHighlightFontObject(fontInstance)
	frame.sidePanelDeleteButton.frame:SetDisabledFontObject(fontInstance)
	frame.sidePanelDeleteButton:SetCallback("OnClick",function(widget,callbackName,value)
        if IsShiftKeyDown() then
            --delete all profiles
            local numPresets = self:CountPresets()
            local prompt = "!!WARNING!!\nDo you wish to delete ALL presets of this dungeon?\nYou are about to delete "..numPresets.." preset(s)\nThis cannot be undone\n"
            MethodDungeonTools:OpenConfirmationFrame(450,150,"Delete ALL presets","Delete",prompt, MethodDungeonTools.DeleteAllPresets)
        else
            MethodDungeonTools:HideAllDialogs()
            frame.DeleteConfirmationFrame:ClearAllPoints()
            frame.DeleteConfirmationFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
            local currentPresetName = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text
            frame.DeleteConfirmationFrame.label:SetText(L"Delete "..currentPresetName.."?")
            frame.DeleteConfirmationFrame:Show()
        end
	end)

	frame.LinkToChatButton = AceGUI:Create("Button")
	frame.LinkToChatButton:SetText(L"Share")
	frame.LinkToChatButton:SetWidth(buttonWidth)
	frame.LinkToChatButton.frame:SetNormalFontObject(fontInstance)
	frame.LinkToChatButton.frame:SetHighlightFontObject(fontInstance)
	frame.LinkToChatButton.frame:SetDisabledFontObject(fontInstance)
	frame.LinkToChatButton:SetCallback("OnClick",function(widget,callbackName,value)
        local distribution = MethodDungeonTools:IsPlayerInGroup()
        if not distribution then return end
        local callback = function()
            frame.LinkToChatButton:SetDisabled(true)
            frame.LinkToChatButton.text:SetTextColor(0.5,0.5,0.5)
            frame.LiveSessionButton:SetDisabled(true)
            frame.LiveSessionButton.text:SetTextColor(0.5,0.5,0.5)
            frame.LinkToChatButton:SetText("...")
            frame.LiveSessionButton:SetText("...")
            MethodDungeonTools:SendToGroup(distribution)
        end
        local presetSize = self:GetPresetSize(false,5)
        if presetSize>25000 then
            local prompt = "You are trying to share a very large preset ("..presetSize.." characters)\nIt is recommended to use the export function and share large presets through wago.io instead.\nAre you sure you want to share this preset?\n"
            MethodDungeonTools:OpenConfirmationFrame(450,150,"Sharing large preset","Share",prompt, callback)
        else
            callback()
        end
	end)
    frame.LinkToChatButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.sidePanelDeleteButton.frame, "ANCHOR_BOTTOMLEFT",frame.LinkToChatButton.frame:GetWidth()*(-2),-frame.LinkToChatButton.frame:GetHeight())
        GameTooltip:AddLine("Share the preset with your party members",1,1,1)
        GameTooltip:Show()
    end)
    frame.LinkToChatButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)
    local inGroup = UnitInRaid("player") or IsInGroup()
    MethodDungeonTools.main_frame.LinkToChatButton:SetDisabled(not inGroup)
    if inGroup then
        MethodDungeonTools.main_frame.LinkToChatButton.text:SetTextColor(1,0.8196,0)
    else
        MethodDungeonTools.main_frame.LinkToChatButton.text:SetTextColor(0.5,0.5,0.5)
    end

    frame.ClearPresetButton = AceGUI:Create("Button")
    frame.ClearPresetButton:SetText(L"Reset")
    frame.ClearPresetButton:SetWidth(buttonWidth)
    frame.ClearPresetButton.frame:SetNormalFontObject(fontInstance)
    frame.ClearPresetButton.frame:SetHighlightFontObject(fontInstance)
    frame.ClearPresetButton.frame:SetDisabledFontObject(fontInstance)
    frame.ClearPresetButton:SetCallback("OnClick",function(widget,callbackName,value)
        MethodDungeonTools:OpenClearPresetDialog()
    end)
    frame.ClearPresetButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.ClearPresetButton.frame, "ANCHOR_BOTTOMLEFT",frame.ClearPresetButton.frame:GetWidth()*(-0),frame.ClearPresetButton.frame:GetHeight())
        GameTooltip:AddLine("Reset the preset to the default state",1,1,1)
        GameTooltip:AddLine("Does not delete your drawings",1,1,1)
        GameTooltip:Show()
    end)
    frame.ClearPresetButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)

    frame.LiveSessionButton = AceGUI:Create("Button")
    frame.LiveSessionButton:SetText("Live")
    frame.LiveSessionButton:SetWidth(buttonWidth)
    frame.LiveSessionButton.frame:SetNormalFontObject(fontInstance)
    frame.LiveSessionButton.frame:SetHighlightFontObject(fontInstance)
    frame.LiveSessionButton.frame:SetDisabledFontObject(fontInstance)
    local c1,c2,c3 = frame.LiveSessionButton.text:GetTextColor()
    frame.LiveSessionButton.normalTextColor = {r = c1,g = c2,b = c3,}
    frame.LiveSessionButton:SetCallback("OnClick",function(widget,callbackName,value)
        if MethodDungeonTools.liveSessionActive then
            MethodDungeonTools:LiveSession_Disable()
        else
            MethodDungeonTools:LiveSession_Enable()
        end
    end)
    frame.LiveSessionButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.LiveSessionButton.frame, "ANCHOR_BOTTOMLEFT",frame.LiveSessionButton.frame:GetWidth()*(-1),frame.LiveSessionButton.frame:GetHeight())
        GameTooltip:AddLine("Start or join the current |cFF00FF00Live Session|r",1,1,1)
        GameTooltip:AddLine("Clicking this button will attempt to join the ongoing Live Session of your group or create a new one if none is found",1,1,1,1)
        GameTooltip:AddLine("The preset will continuously synchronize between all party members participating in the Live Session",1,1,1,1)
        GameTooltip:AddLine("Players can join the live session by either clicking this button or the Live Session chat link",1,1,1,1)
        GameTooltip:AddLine("To share a different preset while the live session is active simply navigate to the preferred preset and click the new 'Set to Live' Button next to the preset-dropdown",1,1,1,1)
        GameTooltip:AddLine("You can always return to the current Live Session preset by clicking the 'Return to Live' button next to the preset-dropdown",1,1,1,1)
        GameTooltip:Show()
    end)
    frame.LiveSessionButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)
    MethodDungeonTools.main_frame.LiveSessionButton:SetDisabled(not inGroup)
    if inGroup then
        MethodDungeonTools.main_frame.LiveSessionButton.text:SetTextColor(1,0.8196,0)
    else
        MethodDungeonTools.main_frame.LiveSessionButton.text:SetTextColor(0.5,0.5,0.5)
    end

    --MDI
    frame.MDIButton = AceGUI:Create("Button")
    frame.MDIButton:SetText(L"MDI")
    frame.MDIButton:SetWidth(buttonWidth)
    frame.MDIButton.frame:SetNormalFontObject(fontInstance)
    frame.MDIButton.frame:SetHighlightFontObject(fontInstance)
    frame.MDIButton.frame:SetDisabledFontObject(fontInstance)
    frame.MDIButton:SetCallback("OnClick",function(widget,callbackName,value)
        MethodDungeonTools:ToggleMDIMode()
    end)
    frame.MDIButton.frame:SetScript("OnEnter",function()
        GameTooltip:SetOwner(frame.MDIButton.frame, "ANCHOR_BOTTOMLEFT",frame.MDIButton.frame:GetWidth()*(-2),frame.MDIButton.frame:GetHeight())
        GameTooltip:AddLine("Open MDI override options",1,1,1)
        GameTooltip:Show()
    end)
    frame.MDIButton.frame:SetScript("OnLeave",function()
        GameTooltip:Hide()
    end)

    --AutomaticColorsCheckbox
    frame.AutomaticColorsCheckSidePanel = AceGUI:Create("CheckBox")
	frame.AutomaticColorsCheckSidePanel:SetLabel("Automatically color pulls")
	frame.AutomaticColorsCheckSidePanel:SetValue(db.colorPaletteInfo.autoColoring)
    frame.AutomaticColorsCheckSidePanel:SetCallback("OnValueChanged",function(widget,callbackName,value)
		db.colorPaletteInfo.autoColoring = value
        MethodDungeonTools:SetPresetColorPaletteInfo()
        frame.AutomaticColorsCheck:SetValue(db.colorPaletteInfo.autoColoring)
        if value == true then
            frame.toggleForceColorBlindMode:SetDisabled(false)
            MethodDungeonTools:ColorAllPulls()
        else
            frame.toggleForceColorBlindMode:SetDisabled(true)
        end
	end)

	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelNewButton)
    frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelRenameButton)
    frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelDeleteButton)
    frame.sidePanel.WidgetGroup:AddChild(frame.ClearPresetButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelImportButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanelExportButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.LinkToChatButton)
    frame.sidePanel.WidgetGroup:AddChild(frame.LiveSessionButton)
	frame.sidePanel.WidgetGroup:AddChild(frame.MDIButton)
    frame.sidePanel.WidgetGroup:AddChild(frame.AutomaticColorsCheckSidePanel)

    --Week Dropdown (Infested / Affixes)
    local function makeAffixString(week,affixes,longText)
        local ret
        local sep = ""
        for _,affixID in ipairs(affixes) do
            local name, _, filedataid = C_ChallengeMode.GetAffixInfo(affixID)
            name = name or "Unknown"
            filedataid = filedataid or 134400 --questionmark
            if longText then
                ret = ret or ""
                ret = ret..sep..name
                sep = ", "
            else
                ret = ret or week..(week>9 and ". " or ".   ")
                if week == MethodDungeonTools:GetCurrentAffixWeek() then
                    ret = WrapTextInColorCode(ret, "FF00FF00")
                end
                ret = ret..CreateTextureMarkup(filedataid, 64, 64, 20, 20, 0.1, 0.9, 0.1, 0.9,0,0).."  "
            end
        end
        local rotation = ""
        if longText then rotation = rotation.." (Rotation " end
        rotation = rotation..((week-1)%4>=2 and "B" or "A")
        if longText then rotation = rotation..")" end
        ret = ret..rotation
        return ret
    end
    frame.sidePanel.affixDropdown = AceGUI:Create("Dropdown")
    local affixDropdown = frame.sidePanel.affixDropdown
    affixDropdown.text:SetJustifyH("LEFT")
    affixDropdown:SetLabel(L"Affixes")

    function affixDropdown:UpdateAffixList()
        local affixWeekMarkups = {}
        for week,affixes in ipairs(affixWeeks) do
            tinsert(affixWeekMarkups,makeAffixString(week,affixes))
        end
        local order = {1,2,3,4,5,6,7,8,9,10,11,12}
        affixDropdown:SetList(affixWeekMarkups,order)
        --mouseover list items
        for itemIdx,item in ipairs(affixDropdown.pullout.items) do
            item:SetOnEnter(function()
                GameTooltip:SetOwner(item.frame, "ANCHOR_LEFT",-11,-25)
                local v = affixWeeks[itemIdx]
                GameTooltip:SetText(makeAffixString(itemIdx,v,true),1,1,1,1)
                GameTooltip:Show()
            end)
            item:SetOnLeave(function()
                GameTooltip:Hide()
            end)
        end
    end
    function affixDropdown:SetAffixWeek(key,ignoreReloadPullButtons,ignoreUpdateProgressBar)
        affixDropdown:SetValue(key)
        if not MethodDungeonTools:GetCurrentAffixWeek() then
            frame.sidePanel.affixWeekWarning.image:Hide()
            frame.sidePanel.affixWeekWarning:SetDisabled(true)
        elseif MethodDungeonTools:GetCurrentAffixWeek() == key then
            frame.sidePanel.affixWeekWarning.image:Hide()
            frame.sidePanel.affixWeekWarning:SetDisabled(true)
        else
            frame.sidePanel.affixWeekWarning.image:Show()
            frame.sidePanel.affixWeekWarning:SetDisabled(false)
        end
        MethodDungeonTools:GetCurrentPreset().week = key
        local teeming = MethodDungeonTools:IsPresetTeeming(MethodDungeonTools:GetCurrentPreset())
        MethodDungeonTools:GetCurrentPreset().value.teeming = teeming

        if MethodDungeonTools.EnemyInfoFrame and MethodDungeonTools.EnemyInfoFrame.frame:IsShown() then MethodDungeonTools:UpdateEnemyInfoData() end
        MethodDungeonTools:UpdateMap(nil,ignoreReloadPullButtons,ignoreUpdateProgressBar)
    end
    affixDropdown:SetCallback("OnValueChanged",function(widget,callbackName,key)
        affixDropdown:SetAffixWeek(key)
        if MethodDungeonTools.liveSessionActive and MethodDungeonTools:GetCurrentPreset().uid == MethodDungeonTools.livePresetUID then
            MethodDungeonTools:LiveSession_SendAffixWeek(key)
        end
    end)
    affixDropdown:SetCallback("OnEnter",function(...)
        local selectedWeek = affixDropdown:GetValue()
        if not selectedWeek then return end
        GameTooltip:SetOwner(affixDropdown.frame, "ANCHOR_LEFT",-6,-41)
        local v = affixWeeks[selectedWeek]
        GameTooltip:SetText(makeAffixString(selectedWeek,v,true),1,1,1,1)
        GameTooltip:Show()
    end)
    affixDropdown:SetCallback("OnLeave",function(...)
        GameTooltip:Hide()
    end)

    frame.sidePanel.WidgetGroup:AddChild(affixDropdown)

    --affix not current week warning
    frame.sidePanel.affixWeekWarning = AceGUI:Create("Icon")
    local affixWeekWarning = frame.sidePanel.affixWeekWarning
    affixWeekWarning:SetImage("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    affixWeekWarning:SetImageSize(25,25)
    affixWeekWarning:SetWidth(35)
    affixWeekWarning:SetCallback("OnEnter",function(...)
        GameTooltip:SetOwner(affixDropdown.frame, "ANCHOR_CURSOR")
        GameTooltip:AddLine(L"The selected affixes are not the ones of the current week",1,1,1)
        GameTooltip:AddLine(L"Click to switch to current week",1,1,1)
        GameTooltip:Show()
    end)
    affixWeekWarning:SetCallback("OnLeave",function(...)
        GameTooltip:Hide()
    end)
    affixWeekWarning:SetCallback("OnClick",function(...)
        if not MethodDungeonTools:GetCurrentAffixWeek() then return end
        affixDropdown:SetAffixWeek(MethodDungeonTools:GetCurrentAffixWeek())
        if MethodDungeonTools.liveSessionActive and MethodDungeonTools:GetCurrentPreset().uid == MethodDungeonTools.livePresetUID then
            MethodDungeonTools:LiveSession_SendAffixWeek(MethodDungeonTools:GetCurrentAffixWeek())
        end
    end)
    affixWeekWarning.image:Hide()
    affixWeekWarning:SetDisabled(true)
    frame.sidePanel.WidgetGroup:AddChild(affixWeekWarning)

    --difficulty slider
	frame.sidePanel.DifficultySlider = AceGUI:Create("Slider")
	frame.sidePanel.DifficultySlider:SetSliderValues(1,35,1)
    frame.sidePanel.DifficultySlider:SetLabel(L"Dungeon Level")
    frame.sidePanel.DifficultySlider.label:SetJustifyH("LEFT")
    frame.sidePanel.DifficultySlider.label:SetFontObject("GameFontNormalSmall")
	frame.sidePanel.DifficultySlider:SetWidth(200)
	frame.sidePanel.DifficultySlider:SetValue(db.currentDifficulty)
    local timer
	frame.sidePanel.DifficultySlider:SetCallback("OnValueChanged",function(widget,callbackName,value)
		local difficulty = tonumber(value)
        if (difficulty>=10 and db.currentDifficulty<10) or (difficulty<10 and db.currentDifficulty>=10) then
            db.currentDifficulty = difficulty or db.currentDifficulty
            MethodDungeonTools:DungeonEnemies_UpdateSeasonalAffix()
            frame.sidePanel.difficultyWarning:Toggle(difficulty)
            MethodDungeonTools:POI_UpdateAll()
            MethodDungeonTools:KillAllAnimatedLines()
            MethodDungeonTools:DrawAllAnimatedLines()
        else
            db.currentDifficulty = difficulty or db.currentDifficulty
        end
        MethodDungeonTools:GetCurrentPreset().difficulty = db.currentDifficulty
        MethodDungeonTools:UpdateProgressbar()
        if MethodDungeonTools.EnemyInfoFrame and MethodDungeonTools.EnemyInfoFrame.frame:IsShown() then MethodDungeonTools:UpdateEnemyInfoData() end
        if timer then timer:Cancel() end
        timer = C_Timer.NewTimer(2, function()
            MethodDungeonTools:ReloadPullButtons()
            if MethodDungeonTools.liveSessionActive then
                local livePreset = MethodDungeonTools:GetCurrentLivePreset()
                local shouldUpdate = livePreset == MethodDungeonTools:GetCurrentPreset()
                if shouldUpdate then MethodDungeonTools:LiveSession_SendDifficulty() end
            end
        end)
	end)
    frame.sidePanel.DifficultySlider:SetCallback("OnMouseUp",function()
        if timer then timer:Cancel() end
        MethodDungeonTools:ReloadPullButtons()
        if MethodDungeonTools.liveSessionActive then
            local livePreset = MethodDungeonTools:GetCurrentLivePreset()
            local shouldUpdate = livePreset == MethodDungeonTools:GetCurrentPreset()
            if shouldUpdate then MethodDungeonTools:LiveSession_SendDifficulty() end
        end
    end)
	frame.sidePanel.DifficultySlider:SetCallback("OnEnter",function()
        GameTooltip:SetOwner(frame.sidePanel.DifficultySlider.frame, "ANCHOR_BOTTOMLEFT",0,40)
        GameTooltip:AddLine("Select the dungeon level",1,1,1)
        GameTooltip:AddLine("The selected level will affect displayed npc health",1,1,1)
        GameTooltip:AddLine("Levels below 10 will hide enemies related to seasonal affixes",1,1,1)
        GameTooltip:Show()
	end)
	frame.sidePanel.DifficultySlider:SetCallback("OnLeave",function()
        GameTooltip:Hide()
	end)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanel.DifficultySlider)

    --dungeon level below 10 warning
    frame.sidePanel.difficultyWarning = AceGUI:Create("Icon")
    local difficultyWarning = frame.sidePanel.difficultyWarning
    difficultyWarning:SetImage("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
    difficultyWarning:SetImageSize(25,25)
    difficultyWarning:SetWidth(35)
    difficultyWarning:SetCallback("OnEnter",function(...)
        GameTooltip:SetOwner(frame.sidePanel.DifficultySlider.frame, "ANCHOR_CURSOR")
        GameTooltip:AddLine("The selected dungeon level is below 10",1,1,1)
        GameTooltip:AddLine("Enemies related to seasonal affixes are currently hidden",1,1,1)
        GameTooltip:AddLine("Click to set dungeon level to 10",1,1,1)
        GameTooltip:Show()
    end)
    difficultyWarning:SetCallback("OnLeave",function(...)
        GameTooltip:Hide()
    end)
    difficultyWarning:SetCallback("OnClick",function(...)
        frame.sidePanel.DifficultySlider:SetValue(10)
        db.currentDifficulty = 10
        MethodDungeonTools:GetCurrentPreset().difficulty = db.currentDifficulty
        MethodDungeonTools:DungeonEnemies_UpdateSeasonalAffix()
        MethodDungeonTools:POI_UpdateAll()
        MethodDungeonTools:UpdateProgressbar()
        MethodDungeonTools:ReloadPullButtons()
        difficultyWarning:Toggle(db.currentDifficulty)
        if MethodDungeonTools.liveSessionActive then
            local livePreset = MethodDungeonTools:GetCurrentLivePreset()
            local shouldUpdate = livePreset == MethodDungeonTools:GetCurrentPreset()
            if shouldUpdate then MethodDungeonTools:LiveSession_SendDifficulty() end
        end
        MethodDungeonTools:KillAllAnimatedLines()
        MethodDungeonTools:DrawAllAnimatedLines()
    end)
    function difficultyWarning:Toggle(difficulty)
        if difficulty<10 then
            self.image:Show()
            self:SetDisabled(false)
        else
            self.image:Hide()
            self:SetDisabled(true)
        end
    end
    difficultyWarning:Toggle(db.currentDifficulty)
    frame.sidePanel.WidgetGroup:AddChild(difficultyWarning)

	frame.sidePanel.middleLine = AceGUI:Create("Heading")
	frame.sidePanel.middleLine:SetWidth(240)
	frame.sidePanel.WidgetGroup:AddChild(frame.sidePanel.middleLine)
    frame.sidePanel.WidgetGroup.frame:SetFrameLevel(3)

	--progress bar
	frame.sidePanel.ProgressBar = CreateFrame("Frame", nil, frame.sidePanel, "ScenarioTrackerProgressBarTemplate")
	frame.sidePanel.ProgressBar:Show()
    frame.sidePanel.ProgressBar:ClearAllPoints()
	frame.sidePanel.ProgressBar:SetPoint("TOP",frame.sidePanel.WidgetGroup.frame,"BOTTOM",-10,5)
    MethodDungeonTools:SkinProgressBar(frame.sidePanel.ProgressBar)
end

---ToggleMDIMode
---Enables display to override beguiling+freehold week
function MethodDungeonTools:ToggleMDIMode()
    db.MDI.enabled = not db.MDI.enabled
    self:DisplayMDISelector()
    if self.liveSessionActive then self:LiveSession_SendMDI("toggle",db.MDI.enabled and "1" or "0") end
end

function MethodDungeonTools:DisplayMDISelector()
    local show = db.MDI.enabled
    db = MethodDungeonTools:GetDB()
    if not MethodDungeonTools.MDISelector then
        MethodDungeonTools.MDISelector = AceGUI:Create("SimpleGroup")
        MethodDungeonTools.MDISelector.frame:SetFrameStrata("HIGH")
        MethodDungeonTools.MDISelector.frame:SetFrameLevel(50)
        MethodDungeonTools.MDISelector.frame:SetBackdropColor(unpack(MethodDungeonTools.BackdropColor))
        --fix show hide
        local frame = MethodDungeonTools.main_frame
        local originalShow,originalHide = frame.Show,frame.Hide
        local widget = MethodDungeonTools.MDISelector.frame
        function frame:Hide(...)
            widget:Hide()
            return originalHide(self, ...)
        end
        function frame:Show(...)
            if db.MDI.enabled then widget:Show() end
            return originalShow(self, ...)
        end

        MethodDungeonTools.MDISelector:SetLayout("Flow")
        MethodDungeonTools.MDISelector.frame.bg = MethodDungeonTools.MDISelector.frame:CreateTexture(nil, "BACKGROUND")
        MethodDungeonTools.MDISelector.frame.bg:SetAllPoints(MethodDungeonTools.MDISelector.frame)
        MethodDungeonTools.MDISelector.frame.bg:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))
        MethodDungeonTools.MDISelector:SetWidth(145)
        MethodDungeonTools.MDISelector:SetHeight(90)
        MethodDungeonTools.MDISelector.frame:ClearAllPoints()
        MethodDungeonTools.MDISelector.frame:SetPoint("BOTTOMRIGHT",MethodDungeonTools.main_frame,"BOTTOMRIGHT",0,0)

        local label = AceGUI:Create("Label")
        label:SetText(L"MDI Mode")
        MethodDungeonTools.MDISelector:AddChild(label)

        --beguiling
        MethodDungeonTools.MDISelector.BeguilingDropDown = AceGUI:Create("Dropdown")
        MethodDungeonTools.MDISelector.BeguilingDropDown:SetLabel(L"Seasonal Affix:")
        local beguilingList = {[1]=L"Beguiling 1 Void",[2]=L"Beguiling 2 Tides",[3]=L"Beguiling 3 Ench.",[13]=L"Reaping",[14]=L"Awakened A",[15]=L"Awakened B"}
        MethodDungeonTools.MDISelector.BeguilingDropDown:SetList(beguilingList)
        MethodDungeonTools.MDISelector.BeguilingDropDown:SetCallback("OnValueChanged",function(widget,callbackName,key)
            local preset = self:GetCurrentPreset()
            preset.mdi.beguiling = key
            db.currentSeason = self:GetEffectivePresetSeason(preset)
            self:UpdateMap()
            if self.liveSessionActive and preset.uid == self.livePresetUID then
                self:LiveSession_SendMDI("beguiling",key)
            end
        end)
        MethodDungeonTools.MDISelector:AddChild(MethodDungeonTools.MDISelector.BeguilingDropDown)

        --freehold
        MethodDungeonTools.MDISelector.FreeholdDropDown = AceGUI:Create("Dropdown")
        MethodDungeonTools.MDISelector.FreeholdDropDown:SetLabel(L"Freehold:")
        local freeholdList = {L"1. Cutwater",L"2. Blacktooth",L"3. Bilge Rats"}
        MethodDungeonTools.MDISelector.FreeholdDropDown:SetList(freeholdList)
        MethodDungeonTools.MDISelector.FreeholdDropDown:SetCallback("OnValueChanged",function(widget,callbackName,key)
            local preset = MethodDungeonTools:GetCurrentPreset()
            preset.mdi.freehold = key
            if preset.mdi.freeholdJoined then
                MethodDungeonTools:DungeonEnemies_UpdateFreeholdCrew(preset.mdi.freehold)
            end
            MethodDungeonTools:DungeonEnemies_UpdateBlacktoothEvent()
            MethodDungeonTools:UpdateProgressbar()
            MethodDungeonTools:ReloadPullButtons()
            if self.liveSessionActive and self:GetCurrentPreset().uid == self.livePresetUID then
                self:LiveSession_SendMDI("freehold",key)
            end
        end)
        MethodDungeonTools.MDISelector:AddChild(MethodDungeonTools.MDISelector.FreeholdDropDown)

        MethodDungeonTools.MDISelector.FreeholdCheck = AceGUI:Create("CheckBox")
        MethodDungeonTools.MDISelector.FreeholdCheck:SetLabel(L"Join Crew")
        MethodDungeonTools.MDISelector.FreeholdCheck:SetCallback("OnValueChanged",function(widget,callbackName,value)
            local preset = MethodDungeonTools:GetCurrentPreset()
            preset.mdi.freeholdJoined = value
            MethodDungeonTools:DungeonEnemies_UpdateFreeholdCrew()
            MethodDungeonTools:ReloadPullButtons()
            MethodDungeonTools:UpdateProgressbar()
            if self.liveSessionActive and self:GetCurrentPreset().uid == self.livePresetUID then
                self:LiveSession_SendMDI("join",value and "1" or "0")
            end
        end)
        MethodDungeonTools.MDISelector:AddChild(MethodDungeonTools.MDISelector.FreeholdCheck)

    end
    if show then
        local preset = MethodDungeonTools:GetCurrentPreset()
        preset.mdi = preset.mdi or {}
        --beguiling
        preset.mdi.beguiling = preset.mdi.beguiling or 1
        MethodDungeonTools.MDISelector.BeguilingDropDown:SetValue(preset.mdi.beguiling)
        db.currentSeason = MethodDungeonTools:GetEffectivePresetSeason(preset)
        MethodDungeonTools:DungeonEnemies_UpdateSeasonalAffix()
        MethodDungeonTools:DungeonEnemies_UpdateBoralusFaction(MethodDungeonTools:GetCurrentPreset().faction)
        --freehold
        preset.mdi.freehold = preset.mdi.freehold or 1
        MethodDungeonTools.MDISelector.FreeholdDropDown:SetValue(preset.mdi.freehold)
        preset.mdi.freeholdJoined = preset.mdi.freeholdJoined or false
        MethodDungeonTools.MDISelector.FreeholdCheck:SetValue(preset.mdi.freeholdJoined)
        MethodDungeonTools:DungeonEnemies_UpdateFreeholdCrew()
        MethodDungeonTools:DungeonEnemies_UpdateBlacktoothEvent()
        MethodDungeonTools:UpdateProgressbar()
        MethodDungeonTools:ReloadPullButtons()
        MethodDungeonTools.MDISelector.frame:Show()
        MethodDungeonTools:ToggleFreeholdSelector(false)
    else
        db.currentSeason = defaultSavedVars.global.currentSeason
        MethodDungeonTools:DungeonEnemies_UpdateSeasonalAffix()
        MethodDungeonTools:DungeonEnemies_UpdateBoralusFaction(MethodDungeonTools:GetCurrentPreset().faction)
        MethodDungeonTools:UpdateFreeholdSelector(MethodDungeonTools:GetCurrentPreset().week)
        MethodDungeonTools:DungeonEnemies_UpdateBlacktoothEvent()
        MethodDungeonTools:UpdateProgressbar()
        MethodDungeonTools:ReloadPullButtons()
        MethodDungeonTools.MDISelector.frame:Hide()
        MethodDungeonTools:ToggleFreeholdSelector(db.currentDungeonIdx == 16)
    end
    MethodDungeonTools:POI_UpdateAll()
    MethodDungeonTools:KillAllAnimatedLines()
    MethodDungeonTools:DrawAllAnimatedLines()
end


function MethodDungeonTools:UpdatePresetDropDown()
	local dropdown = MethodDungeonTools.main_frame.sidePanel.WidgetGroup.PresetDropDown
	local presetList = {}
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		table.insert(presetList,k,v.text)
	end
	dropdown:SetList(presetList)
	dropdown:SetValue(db.currentPreset[db.currentDungeonIdx])
    dropdown:ClearFocus()
end

function MethodDungeonTools:UpdatePresetDropdownTextColor(forceReset)
    local preset = self:GetCurrentPreset()
    local livePreset = self:GetCurrentLivePreset()
    if self.liveSessionActive and preset == livePreset and (not forceReset) then
        local dropdown = MethodDungeonTools.main_frame.sidePanel.WidgetGroup.PresetDropDown
        dropdown.text:SetTextColor(0,1,0,1)
    else
        local dropdown = MethodDungeonTools.main_frame.sidePanel.WidgetGroup.PresetDropDown
        dropdown.text:SetTextColor(1,1,1,1)
    end
end

---FormatEnemyForces
function MethodDungeonTools:FormatEnemyForces(forces,forcesmax,progressbar)
    if not forcesmax then forcesmax = MethodDungeonTools:IsCurrentPresetTeeming() and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal end
    if db.enemyForcesFormat == 1 then
        if progressbar then return forces.."/"..forcesmax end
        return forces
    elseif db.enemyForcesFormat == 2 then
        if progressbar then return string.format((forces.."/"..forcesmax.." (%.2f%%)"),(forces/forcesmax)*100) end
        return string.format(forces.." (%.2f%%)",(forces/forcesmax)*100)
    end
end

---Progressbar_SetValue
---Sets the value/progress/color of the count progressbar to the apropriate data
function MethodDungeonTools:Progressbar_SetValue(self,totalCurrent,totalMax)
	local percent = (totalCurrent/totalMax)*100
	if percent >= 102 then
		if totalCurrent-totalMax > 8 then
			self.Bar:SetStatusBarColor(1,0,0,1)
		else
			self.Bar:SetStatusBarColor(0,1,0,1)
		end
    elseif percent >= 100 then
        self.Bar:SetStatusBarColor(0,1,0,1)
	else
		self.Bar:SetStatusBarColor(0.26,0.42,1)
	end
	self.Bar:SetValue(percent)
	self.Bar.Label:SetText(MethodDungeonTools:FormatEnemyForces(totalCurrent,totalMax,true))
	self.AnimValue = percent
end

---UpdateProgressbar
---Update the progressbar on the sidepanel with the correct values
function MethodDungeonTools:UpdateProgressbar()
	local teeming = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
    MethodDungeonTools:EnsureDBTables()
    local grandTotal = MethodDungeonTools:CountForces()
	MethodDungeonTools:Progressbar_SetValue(MethodDungeonTools.main_frame.sidePanel.ProgressBar,grandTotal,teeming==true and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal)
end

function MethodDungeonTools:OnPan(cursorX, cursorY)
    local scrollFrame = MethodDungeonToolsScrollFrame
    local scale = MethodDungeonToolsMapPanelFrame:GetScale()/1.5
    local deltaX = (scrollFrame.cursorX - cursorX)/scale
    local deltaY = (cursorY - scrollFrame.cursorY)/scale

    if(scrollFrame.panning)then
		local newHorizontalPosition = max(0, deltaX + scrollFrame:GetHorizontalScroll())
		newHorizontalPosition = min(newHorizontalPosition, scrollFrame.maxX)
		local newVerticalPosition = max(0, deltaY + scrollFrame:GetVerticalScroll())
		newVerticalPosition = min(newVerticalPosition, scrollFrame.maxY)
		scrollFrame:SetHorizontalScroll(newHorizontalPosition)
		scrollFrame:SetVerticalScroll(newVerticalPosition)
		scrollFrame.cursorX = cursorX
		scrollFrame.cursorY = cursorY

        scrollFrame.wasPanningLastFrame = true;
        scrollFrame.lastDeltaX = deltaX;
        scrollFrame.lastDeltaY = deltaY;

    else
        if(scrollFrame.wasPanningLastFrame)then

            scrollFrame.isFadeOutPanning = true
            scrollFrame.fadeOutXStart = scrollFrame.lastDeltaX
            scrollFrame.fadeOutYStart = scrollFrame.lastDeltaY
            scrollFrame.panDuration = 0

            scrollFrame.wasPanningLastFrame = false;
        end
    end
end

function MethodDungeonTools:OnPanFadeOut(deltaTime)
    local scrollFrame = MethodDungeonToolsScrollFrame
    local panDuration = 0.5
    local panAtenuation = 7
    if(scrollFrame.isFadeOutPanning)then
        scrollFrame.panDuration = scrollFrame.panDuration + deltaTime

        local phase = scrollFrame.panDuration / panDuration
        local phaseLog = -math.log(phase)
        local stepX = (scrollFrame.fadeOutXStart * phaseLog) / panAtenuation
        local stepY = (scrollFrame.fadeOutYStart * phaseLog) / panAtenuation

        local newHorizontalPosition = max(0, stepX + scrollFrame:GetHorizontalScroll())
        newHorizontalPosition = min(newHorizontalPosition, scrollFrame.maxX)
        local newVerticalPosition = max(0, stepY + scrollFrame:GetVerticalScroll())
        newVerticalPosition = min(newVerticalPosition, scrollFrame.maxY)
        scrollFrame:SetHorizontalScroll(newHorizontalPosition)
        scrollFrame:SetVerticalScroll(newVerticalPosition)

        if(scrollFrame.panDuration > panDuration)then
            scrollFrame.isFadeOutPanning = false
        end
    end
end

function MethodDungeonTools:ExportCurrentZoomPanSettings()
    local mainFrame = MethodDungeonToolsMapPanelFrame
    local scrollFrame = MethodDungeonToolsScrollFrame

    local zoom = MethodDungeonToolsMapPanelFrame:GetScale()
    local panH = MethodDungeonToolsScrollFrame:GetHorizontalScroll() / MethodDungeonTools:GetScale()
    local panV = MethodDungeonToolsScrollFrame:GetVerticalScroll() / MethodDungeonTools:GetScale()

    local output = "        ["..db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel.."] = {\n"
    output = output.."            zoomScale = "..zoom..";\n"
    output = output.."            horizontalPan = "..panH..";\n"
    output = output.."            verticalPan = "..panV..";\n"
    output = output.."        };\n"

    MethodDungeonTools:HideAllDialogs()
    MethodDungeonTools.main_frame.ExportFrame:Show()
    MethodDungeonTools.main_frame.ExportFrame:ClearAllPoints()
    MethodDungeonTools.main_frame.ExportFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
    MethodDungeonTools.main_frame.ExportFrameEditbox:SetText(output)
    MethodDungeonTools.main_frame.ExportFrameEditbox:HighlightText(0, string.len(output))
    MethodDungeonTools.main_frame.ExportFrameEditbox:SetFocus()
    MethodDungeonTools.main_frame.ExportFrameEditbox:SetLabel("Current pan/zoom settings");
end


function MethodDungeonTools:ZoomMapToDefault()
    local currentMap = db.presets[db.currentDungeonIdx]
    local currentSublevel = currentMap[db.currentPreset[db.currentDungeonIdx]].value.currentSublevel
    local mainFrame = MethodDungeonToolsMapPanelFrame
    local scrollFrame = MethodDungeonToolsScrollFrame

    local currentMapInfo = MethodDungeonTools.mapInfo[db.currentDungeonIdx]
    if(currentMapInfo and currentMapInfo.viewportPositionOverrides and currentMapInfo.viewportPositionOverrides[currentSublevel])then
        local data = currentMapInfo.viewportPositionOverrides[currentSublevel];

        local scaledSizeX = mainFrame:GetWidth() * data.zoomScale
        local scaledSizeY = mainFrame:GetHeight() * data.zoomScale

        scrollFrame.maxX = (scaledSizeX - mainFrame:GetWidth()) / data.zoomScale
        scrollFrame.maxY = (scaledSizeY - mainFrame:GetHeight()) / data.zoomScale
        scrollFrame.zoomedIn = abs(data.zoomScale - 1) > 0.02

        mainFrame:SetScale(data.zoomScale)

        scrollFrame:SetHorizontalScroll(data.horizontalPan * MethodDungeonTools:GetScale())
        scrollFrame:SetVerticalScroll(data.verticalPan * MethodDungeonTools:GetScale())

    else
        scrollFrame.maxX = 1
        scrollFrame.maxY = 1
        scrollFrame.zoomedIn = false

        mainFrame:SetScale(1);

        scrollFrame:SetHorizontalScroll(0)
        scrollFrame:SetVerticalScroll(0)
    end

end

function MethodDungeonTools:ZoomMap(delta)
	local scrollFrame = MethodDungeonToolsScrollFrame
    if not scrollFrame:GetLeft() then return end
	local oldScrollH = scrollFrame:GetHorizontalScroll()
	local oldScrollV = scrollFrame:GetVerticalScroll()

	local mainFrame = MethodDungeonToolsMapPanelFrame

	local oldScale = mainFrame:GetScale()
	local newScale = oldScale + delta * 0.3

	newScale = max(1, newScale)
	newScale = min(15, newScale)

	mainFrame:SetScale(newScale)

	local scaledSizeX = mainFrame:GetWidth() * newScale
	local scaledSizeY = mainFrame:GetHeight() * newScale

	scrollFrame.maxX = (scaledSizeX - mainFrame:GetWidth()) / newScale
	scrollFrame.maxY = (scaledSizeY - mainFrame:GetHeight()) / newScale
	scrollFrame.zoomedIn = abs(newScale - 1) > 0.02

	local cursorX,cursorY = GetCursorPosition()
	local frameX = (cursorX / UIParent:GetScale()) - scrollFrame:GetLeft()
	local frameY = scrollFrame:GetTop() - (cursorY / UIParent:GetScale())
	local scaleChange = newScale / oldScale
	local newScrollH =  (scaleChange * frameX - frameX) / newScale + oldScrollH
	local newScrollV =  (scaleChange * frameY - frameY) / newScale + oldScrollV

	newScrollH = min(newScrollH, scrollFrame.maxX)
	newScrollH = max(0, newScrollH)
	newScrollV = min(newScrollV, scrollFrame.maxY)
	newScrollV = max(0, newScrollV)

	scrollFrame:SetHorizontalScroll(newScrollH)
	scrollFrame:SetVerticalScroll(newScrollV)

    MethodDungeonTools:SetPingOffsets(newScale)
end

---ActivatePullTooltip
---
function MethodDungeonTools:ActivatePullTooltip(pull)
    local pullTooltip = MethodDungeonTools.pullTooltip
    --[[
    if not pullTooltip.ranOnce then
        --fix elvui skinning
        pullTooltip:SetPoint("TOPRIGHT",UIParent,"BOTTOMRIGHT")
        pullTooltip:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT")
        pullTooltip:Show()
        pullTooltip.ranOnce = true
    end
    ]]
    pullTooltip.currentPull = pull
    pullTooltip:Show()
end

---UpdatePullTooltip
---Updates the tooltip which is being displayed when a pull is mouseovered
function MethodDungeonTools:UpdatePullTooltip(tooltip)
    local frame = MethodDungeonTools.main_frame
	if not MouseIsOver(frame.sidePanel.pullButtonsScrollFrame.frame) then
        tooltip:Hide()
    elseif MouseIsOver(frame.sidePanel.newPullButton.frame) then
        tooltip:Hide()
	else
		if frame.sidePanel.newPullButtons and tooltip.currentPull and frame.sidePanel.newPullButtons[tooltip.currentPull] then
            --enemy portraits
            local showData
			for k,v in pairs(frame.sidePanel.newPullButtons[tooltip.currentPull].enemyPortraits) do
				if MouseIsOver(v) then
					if v:IsShown() then
                        --model
						if v.enemyData.displayId and (not tooltip.modelNpcId or (tooltip.modelNpcId ~= v.enemyData.displayId)) then
							tooltip.Model:SetDisplayInfo(v.enemyData.displayId)
							tooltip.modelNpcId = v.enemyData.displayId
						end
                        --topString
                        local newLine = "\n"
                        local text = newLine..newLine..newLine..v.enemyData.name.." x"..v.enemyData.quantity..newLine
                        text = text..L"Level "..v.enemyData.level.." "..v.enemyData.creatureType..newLine
                        local boss = v.enemyData.isBoss or false
                        local health = MethodDungeonTools:CalculateEnemyHealth(boss,v.enemyData.baseHealth,db.currentDifficulty,v.enemyData.ignoreFortified)
                        text = text.."血量 "..MethodDungeonTools:FormatEnemyHealth(health)..""..newLine

                        local totalForcesMax = MethodDungeonTools:IsCurrentPresetTeeming() and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal
                        local count = MethodDungeonTools:IsCurrentPresetTeeming() and v.enemyData.teemingCount or v.enemyData.count
                        text = text..L"Forces: "..MethodDungeonTools:FormatEnemyForces(count,totalForcesMax,false)

                        tooltip.topString:SetText(text)
                        showData = true
					end
					break
				end
			end
            if showData then
                tooltip.topString:Show()
                tooltip.Model:Show()
            else
                tooltip.topString:Hide()
                tooltip.Model:Hide()
            end

            local countEnemies = 0
            for k,v in pairs(frame.sidePanel.newPullButtons[tooltip.currentPull].enemyPortraits) do
                if v:IsShown() then countEnemies = countEnemies + 1 end
            end
            if countEnemies == 0 then
                tooltip:Hide()
                return
            end
            local pullForces = MethodDungeonTools:CountForces(tooltip.currentPull,true)
            local totalForces = MethodDungeonTools:CountForces(tooltip.currentPull,false)
            local totalForcesMax = MethodDungeonTools:IsCurrentPresetTeeming() and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal

            local text = L"Forces: "..MethodDungeonTools:FormatEnemyForces(pullForces,totalForcesMax,false)
            text = text.. L"\nTotal :"..MethodDungeonTools:FormatEnemyForces(totalForces,totalForcesMax,true)

            tooltip.botString:SetText(text)
            tooltip.botString:Show()
		end
	end
end

---CountForces
---Counts total selected enemy forces in the current preset up to pull
function MethodDungeonTools:CountForces(currentPull,currentOnly)
    --count up to and including the currently selected pull
    currentPull = currentPull or 1000
    local preset = self:GetCurrentPreset()
    local teeming = self:IsCurrentPresetTeeming()
    local pullCurrent = 0
    for pullIdx,pull in pairs(preset.value.pulls) do
        if not currentOnly or (currentOnly and pullIdx == currentPull) then
            if pullIdx <= currentPull then
                for enemyIdx,clones in pairs(pull) do
                    if tonumber(enemyIdx) then
                        for k,v in pairs(clones) do
                            if MethodDungeonTools:IsCloneIncluded(enemyIdx,v) then
                                local count = teeming
                                        and self.dungeonEnemies[db.currentDungeonIdx][enemyIdx].teemingCount
                                        or self.dungeonEnemies[db.currentDungeonIdx][enemyIdx].count
                                pullCurrent = pullCurrent + count
                            end
                        end
                    end
                end
            else
                break
            end
        end
    end
    return pullCurrent
end

local emissaryIds = {[155432]=true,[155433]=true,[155434]=true}

---Checks if the specified clone is part of the current map configuration
function MethodDungeonTools:IsCloneIncluded(enemyIdx,cloneIdx)
    local preset = MethodDungeonTools:GetCurrentPreset()
    local isCloneBlacktoothEvent = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].blacktoothEvent
    local cloneFaction = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].faction

    local week = self:GetEffectivePresetWeek()

    if db.currentSeason ~= 3 then
        if emissaryIds[MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx].id] then return false end
    elseif db.currentSeason ~= 4 then
        if MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx].corrupted then return false end
    end

    --beguiling weekly configuration
    local weekData = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].week
    if weekData then
        if weekData[week] and not (cloneFaction and cloneFaction~= preset.faction) and db.currentDifficulty >= 10 then
            return true
        else
            return false
        end
    end

    week = week%3
    if week == 0 then week = 3 end
    local isBlacktoothWeek = week == 2

    if not isCloneBlacktoothEvent or isBlacktoothWeek then
        if not (cloneFaction and cloneFaction~= preset.faction) then
            local isCloneTeeming = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].teeming
            local isCloneNegativeTeeming = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].negativeTeeming
            if MethodDungeonTools:IsCurrentPresetTeeming() or ((isCloneTeeming and isCloneTeeming == false) or (not isCloneTeeming)) then
                if not(MethodDungeonTools:IsCurrentPresetTeeming() and isCloneNegativeTeeming) then
                    return true
                end
            end
        end
    end
end

---IsCurrentPresetTeeming
---Returns true if the current preset has teeming turned on, false otherwise
function MethodDungeonTools:IsCurrentPresetTeeming()
    --return self:GetCurrentPreset().week
    return db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.teeming
end

---IsCurrentPresetFortified
function MethodDungeonTools:IsCurrentPresetFortified()
    return self:GetCurrentPreset().week%2 == 0
end

---IsCurrentPresetTyrannical
function MethodDungeonTools:IsCurrentPresetTyrannical()
    return self:GetCurrentPreset().week%2 == 1
end

---MouseDownHook
function MethodDungeonTools:MouseDownHook()
    return
end

---MethodDungeonTools.OnMouseDown
---Handles mouse-down events on the map scrollframe
MethodDungeonTools.OnMouseDown = function(self,button)
	local scrollFrame = MethodDungeonTools.main_frame.scrollFrame
	if scrollFrame.zoomedIn then
		scrollFrame.panning = true
		scrollFrame.cursorX,scrollFrame.cursorY = GetCursorPosition()
	end
    scrollFrame.oldX = scrollFrame.cursorX
    scrollFrame.oldY = scrollFrame.cursorY
    MethodDungeonTools:MouseDownHook()
end

---MethodDungeonTools.OnMouseUp
---handles mouse-up events on the map scrollframe
MethodDungeonTools.OnMouseUp = function(self,button)
	local scrollFrame = MethodDungeonTools.main_frame.scrollFrame
    if scrollFrame.panning then scrollFrame.panning = false end

    --play minimap ping on right click at cursor position
    --only ping if we didnt pan
    if scrollFrame.oldX==scrollFrame.cursorX or scrollFrame.oldY==scrollFrame.cursorY then
        if button == "RightButton" then
            local x,y = MethodDungeonTools:GetCursorPosition()
            MethodDungeonTools:PingMap(x,y)
            local sublevel = MethodDungeonTools:GetCurrentSubLevel()
            if MethodDungeonTools.liveSessionActive then MethodDungeonTools:LiveSession_SendPing(x,y,sublevel) end
        end
    end
end

---PingMap
---Pings the map
function MethodDungeonTools:PingMap(x,y)
    self.ping:ClearAllPoints()
    self.ping:SetPoint("CENTER",self.main_frame.mapPanelTile1,"TOPLEFT",x,y)
    self.ping:SetModel("interface/minimap/ping/minimapping.m2")
    local mainFrame = MethodDungeonToolsMapPanelFrame
    local mapScale = mainFrame:GetScale()
    self:SetPingOffsets(mapScale)
    self.ping:Show()
    UIFrameFadeOut(self.ping, 2, 1, 0)
    self.ping:SetSequence(0)
end

function MethodDungeonTools:SetPingOffsets(mapScale)
    local scale = 0.35
    local offset = (10.25/1000)*mapScale
    MethodDungeonTools.ping:SetTransform(offset,offset,0,0,0,0,scale)
end

---SetCurrentSubLevel
---Sets the sublevel of the currently active preset, need to UpdateMap to reflect the change in UI
function MethodDungeonTools:SetCurrentSubLevel(sublevel)
    MethodDungeonTools:GetCurrentPreset().value.currentSublevel = sublevel
end

---GetCurrentPull
---Returns the current pull of the currently active preset
function MethodDungeonTools:GetCurrentPull()
    local selection = MethodDungeonTools:GetSelection()
    return selection[#selection]
end

---GetCurrentSubLevel
---Returns the sublevel of the currently active preset
function MethodDungeonTools:GetCurrentSubLevel()
	return MethodDungeonTools:GetCurrentPreset().value.currentSublevel
end

---GetCurrentPreset
---Returns the current preset
function MethodDungeonTools:GetCurrentPreset()
    return db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
end

---GetCurrentLivePreset
function MethodDungeonTools:GetCurrentLivePreset()
    if not self.livePresetUID then return end
    if self.liveUpdateFrameOpen then
        for fullName,cachedPreset in pairs(self.transmissionCache) do
            if cachedPreset.uid == self.livePresetUID then
                return cachedPreset
            end
        end
    end
    for dungeonIdx,presets in pairs(db.presets) do
        for presetIdx,preset in pairs(presets) do
            if preset.uid and preset.uid == self.livePresetUID then
                return preset,presetIdx
            end
        end
    end
end

---GetEffectivePresetWeek
function MethodDungeonTools:GetEffectivePresetWeek(preset)
    preset = preset or self:GetCurrentPreset()
    local week
    if db.MDI.enabled then
        week = preset.mdi.beguiling or 1
        if week == 14 then week = 1 end
        if week == 15 then week = 3 end
    else
        week = preset.week
    end
    return week
end

---GetEffectivePresetSeason
function MethodDungeonTools:GetEffectivePresetSeason(preset)
    local season = db.currentSeason
    if db.MDI.enabled then
        local mdiWeek = preset.mdi.beguiling
        season = (mdiWeek == 1 or mdiWeek == 2 or mdiWeek == 3) and 3 or mdiWeek == 13 and 2 or (mdiWeek == 14 or mdiWeek == 15) and 4
    end
    return season
end

---ReturnToLivePreset
function MethodDungeonTools:ReturnToLivePreset()
    local preset,presetIdx = self:GetCurrentLivePreset()
    self:UpdateToDungeon(preset.value.currentDungeonIdx,true)
    db.currentPreset[db.currentDungeonIdx] = presetIdx
    self:UpdatePresetDropDown()
    self:UpdateMap()
end

---SetLivePreset
function MethodDungeonTools:SetLivePreset()
    local preset = self:GetCurrentPreset()
    self:SetUniqueID(preset)
    self.livePresetUID = preset.uid
    self:LiveSession_SendPreset(preset)
    self:UpdatePresetDropdownTextColor()
    self.main_frame.setLivePresetButton:Hide()
    self.main_frame.liveReturnButton:Hide()
end

---IsWeekTeeming
---Returns if the current week has an affix week set that inlcludes the teeming affix
function MethodDungeonTools:IsWeekTeeming(week)
    if not week then week = MethodDungeonTools:GetCurrentAffixWeek() or 1 end
    return affixWeeks[week][1] == 5
end

---IsPresetTeeming
---Returns if the preset is set to a week which contains the teeming affix
function MethodDungeonTools:IsPresetTeeming(preset)
    return MethodDungeonTools:IsWeekTeeming(preset.week)
end

function MethodDungeonTools:GetRiftOffsets()
    local week = self:GetEffectivePresetWeek()
    local preset = self:GetCurrentPreset()
    preset.value.riftOffsets = preset.value.riftOffsets or {}
    local riftOffsets = preset.value.riftOffsets
    riftOffsets[week] = riftOffsets[week] or {}
    return riftOffsets[week]
end


function MethodDungeonTools:MakeMapTexture(frame)
    MethodDungeonTools.contextMenuList = {}

    tinsert(MethodDungeonTools.contextMenuList, {
        text = "Close",
        notCheckable = 1,
        func = frame.contextDropdown:Hide()
    })

	-- Scroll Frame
	if frame.scrollFrame == nil then
		frame.scrollFrame = CreateFrame("ScrollFrame", "MethodDungeonToolsScrollFrame",frame)
		frame.scrollFrame:ClearAllPoints()
		frame.scrollFrame:SetSize(sizex*db.scale, sizey*db.scale)
		--frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.scrollFrame:SetAllPoints(frame)

		-- Enable mousewheel scrolling
		frame.scrollFrame:EnableMouseWheel(true)
		frame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            MethodDungeonTools:ZoomMap(delta)
		end)

		--PAN
		frame.scrollFrame:EnableMouse(true)
		frame.scrollFrame:SetScript("OnMouseDown", MethodDungeonTools.OnMouseDown)
		frame.scrollFrame:SetScript("OnMouseUp", MethodDungeonTools.OnMouseUp)


		frame.scrollFrame:SetScript("OnUpdate", function(self,elapsed)
			local x, y = GetCursorPosition()
			MethodDungeonTools:OnPan(x, y)
            MethodDungeonTools:OnPanFadeOut(elapsed)
        end)

		if frame.mapPanelFrame == nil then
			frame.mapPanelFrame = CreateFrame("frame","MethodDungeonToolsMapPanelFrame",nil)
			frame.mapPanelFrame:ClearAllPoints()
			frame.mapPanelFrame:SetSize(sizex*db.scale, sizey*db.scale)
			--frame.mapPanelFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            frame.mapPanelFrame:SetAllPoints(frame)
		end

		--create the 12 tiles and set the scrollchild
		for i=1,12 do
			frame["mapPanelTile"..i] = frame.mapPanelFrame:CreateTexture("MethodDungeonToolsmapPanelTile"..i, "BACKGROUND")
			frame["mapPanelTile"..i]:SetDrawLayer(canvasDrawLayer, 0)
			--frame["mapPanelTile"..i]:SetAlpha(0.3)
			frame["mapPanelTile"..i]:SetSize(frame:GetWidth()/4+(5*db.scale),frame:GetWidth()/4+(5*db.scale))
		end
		frame.mapPanelTile1:SetPoint("TOPLEFT",frame.mapPanelFrame,"TOPLEFT",0,0)
		frame.mapPanelTile2:SetPoint("TOPLEFT",frame.mapPanelTile1,"TOPRIGHT")
		frame.mapPanelTile3:SetPoint("TOPLEFT",frame.mapPanelTile2,"TOPRIGHT")
		frame.mapPanelTile4:SetPoint("TOPLEFT",frame.mapPanelTile3,"TOPRIGHT")
		frame.mapPanelTile5:SetPoint("TOPLEFT",frame.mapPanelTile1,"BOTTOMLEFT")
		frame.mapPanelTile6:SetPoint("TOPLEFT",frame.mapPanelTile5,"TOPRIGHT")
		frame.mapPanelTile7:SetPoint("TOPLEFT",frame.mapPanelTile6,"TOPRIGHT")
		frame.mapPanelTile8:SetPoint("TOPLEFT",frame.mapPanelTile7,"TOPRIGHT")
		frame.mapPanelTile9:SetPoint("TOPLEFT",frame.mapPanelTile5,"BOTTOMLEFT")
		frame.mapPanelTile10:SetPoint("TOPLEFT",frame.mapPanelTile9,"TOPRIGHT")
		frame.mapPanelTile11:SetPoint("TOPLEFT",frame.mapPanelTile10,"TOPRIGHT")
		frame.mapPanelTile12:SetPoint("TOPLEFT",frame.mapPanelTile11,"TOPRIGHT")

        --create the 150 large map tiles
        for i=1,10 do
            for j=1,15 do
                frame["largeMapPanelTile"..i..j] = frame.mapPanelFrame:CreateTexture("MethodDungeonToolsLargeMapPanelTile"..i..j, "BACKGROUND")
                local tile = frame["largeMapPanelTile"..i..j]
                tile:SetDrawLayer(canvasDrawLayer, 5)
                tile:SetSize(frame:GetWidth()/15,frame:GetWidth()/15)
                if i==1 and j==1 then
                    --to mapPanel
                    tile:SetPoint("TOPLEFT",frame.mapPanelFrame,"TOPLEFT",0,0)
                elseif j==1 then
                    --to tile above
                    tile:SetPoint("TOPLEFT",frame["largeMapPanelTile"..(i-1)..j],"BOTTOMLEFT",0,0)
                else
                    --to tile to the left
                    tile:SetPoint("TOPLEFT",frame["largeMapPanelTile"..i..(j-1)],"TOPRIGHT",0,0)
                end
                tile:SetColorTexture(i/10,j/10,0,1)
                tile:Hide()
            end
        end


		frame.scrollFrame:SetScrollChild(frame.mapPanelFrame)

        frame.scrollFrame.cursorX = 0
        frame.scrollFrame.cursorY = 0

        frame.scrollFrame.queuedDeltaX = 0;
        frame.scrollFrame.queuedDeltaY = 0;
	end

end

local function round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end
function MethodDungeonTools:CalculateEnemyHealth(boss,baseHealth,level,ignoreFortified)
    local fortified = MethodDungeonTools:IsCurrentPresetFortified()
    local tyrannical = MethodDungeonTools:IsCurrentPresetTyrannical()
	local mult = 1
	if boss == false and fortified == true and (not ignoreFortified) then mult = 1.2 end
	if boss == true and tyrannical == true then mult = 1.4 end
	mult = round((1.10^math.max(level-2,0))*mult,2)
	return round(mult*baseHealth,0)
end

function MethodDungeonTools:ReverseCalcEnemyHealth(unit,level,boss)
    local health = UnitHealthMax(unit)
    local fortified = MethodDungeonTools:IsCurrentPresetFortified()
    local tyrannical = MethodDungeonTools:IsCurrentPresetTyrannical()
    local mult = 1
    if boss == false and fortified == true then mult = 1.2 end
    if boss == true and tyrannical == true then mult = 1.4 end
    mult = round((1.10^math.max(level-2,0))*mult,2)
    local baseHealth = health/mult
    return baseHealth
end

function MethodDungeonTools:FormatEnemyHealth(amount)
	amount = tonumber(amount)
    if not amount then return "" end
    if amount < 1e3 then
        return 0
    elseif amount >= 1e12 then
        return string.format("%.3ft", amount/1e12)
    elseif amount >= 1e9 then
        return string.format("%.3fb", amount/1e9)
    elseif amount >= 1e6 then
        return string.format("%.2fm", amount/1e6)
    elseif amount >= 1e3 then
        return string.format("%.1fk", amount/1e3)
    end
end

function MethodDungeonTools:UpdateDungeonEnemies()
    MethodDungeonTools:DungeonEnemies_UpdateEnemies()
end

function MethodDungeonTools:HideAllDialogs()
	MethodDungeonTools.main_frame.presetCreationFrame:Hide()
	MethodDungeonTools.main_frame.presetImportFrame:Hide()
	MethodDungeonTools.main_frame.ExportFrame:Hide()
	MethodDungeonTools.main_frame.RenameFrame:Hide()
	MethodDungeonTools.main_frame.ClearConfirmationFrame:Hide()
	MethodDungeonTools.main_frame.DeleteConfirmationFrame:Hide()
    MethodDungeonTools.main_frame.automaticColorsFrame.CustomColorFrame:Hide()
    MethodDungeonTools.main_frame.automaticColorsFrame:Hide()
    if MethodDungeonTools.main_frame.ConfirmationFrame then MethodDungeonTools.main_frame.ConfirmationFrame:Hide() end
end

function MethodDungeonTools:OpenImportPresetDialog()
	MethodDungeonTools:HideAllDialogs()
    MethodDungeonTools.main_frame.presetImportFrame:ClearAllPoints()
	MethodDungeonTools.main_frame.presetImportFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
	MethodDungeonTools.main_frame.presetImportFrame:Show()
	MethodDungeonTools.main_frame.presetImportBox:SetText("")
	MethodDungeonTools.main_frame.presetImportBox:SetFocus()
    MethodDungeonTools.main_frame.presetImportLabel:SetText(nil)
end

function MethodDungeonTools:OpenNewPresetDialog()
	MethodDungeonTools:HideAllDialogs()
	local presetList = {}
	local countPresets = 0
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		if v.text ~= "<New Preset>" then
			table.insert(presetList,k,v.text)
			countPresets=countPresets+1
		end
	end
	table.insert(presetList,1,L"Empty")
	MethodDungeonTools.main_frame.PresetCreationDropDown:SetList(presetList)
	MethodDungeonTools.main_frame.PresetCreationDropDown:SetValue(1)
	MethodDungeonTools.main_frame.PresetCreationEditbox:SetText(L"Preset "..countPresets+1)
    MethodDungeonTools.main_frame.presetCreationFrame:ClearAllPoints()
	MethodDungeonTools.main_frame.presetCreationFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
	MethodDungeonTools.main_frame.presetCreationFrame:SetStatusText("")
	MethodDungeonTools.main_frame.presetCreationFrame:Show()
	MethodDungeonTools.main_frame.presetCreationCreateButton:SetDisabled(false)
	MethodDungeonTools.main_frame.presetCreationCreateButton.text:SetTextColor(1,0.8196,0)
	MethodDungeonTools.main_frame.PresetCreationEditbox:SetFocus()
	MethodDungeonTools.main_frame.PresetCreationEditbox:HighlightText(0,50)
	MethodDungeonTools.main_frame.presetImportBox:SetText("")
end

function MethodDungeonTools:OpenClearPresetDialog()
    MethodDungeonTools:HideAllDialogs()
    MethodDungeonTools.main_frame.ClearConfirmationFrame:ClearAllPoints()
    MethodDungeonTools.main_frame.ClearConfirmationFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
    local currentPresetName = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text
    MethodDungeonTools.main_frame.ClearConfirmationFrame.label:SetText(L"Reset "..currentPresetName.."?")
    MethodDungeonTools.main_frame.ClearConfirmationFrame:Show()
end

function MethodDungeonTools:OpenAutomaticColorsDialog()
	MethodDungeonTools:HideAllDialogs()
	MethodDungeonTools.main_frame.automaticColorsFrame:ClearAllPoints()
	MethodDungeonTools.main_frame.automaticColorsFrame:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
	MethodDungeonTools.main_frame.automaticColorsFrame:SetStatusText("")
	MethodDungeonTools.main_frame.automaticColorsFrame:Show()
    MethodDungeonTools.main_frame.automaticColorsFrame.CustomColorFrame:Hide()
    if db.colorPaletteInfo.colorPaletteIdx == 6 then
        MethodDungeonTools:OpenCustomColorsDialog()
    end

end

function MethodDungeonTools:OpenCustomColorsDialog(frame)
	MethodDungeonTools:HideAllDialogs()
    MethodDungeonTools.main_frame.automaticColorsFrame:Show() --Not the prettiest way to handle this, but it works.
	MethodDungeonTools.main_frame.automaticColorsFrame.CustomColorFrame:ClearAllPoints()
    MethodDungeonTools.main_frame.automaticColorsFrame.CustomColorFrame:SetPoint("CENTER",264,-7)
	MethodDungeonTools.main_frame.automaticColorsFrame.CustomColorFrame:SetStatusText("")
	MethodDungeonTools.main_frame.automaticColorsFrame.CustomColorFrame:Show()
end

function MethodDungeonTools:UpdateDungeonDropDown()
	local group = MethodDungeonTools.main_frame.DungeonSelectionGroup
    group.DungeonDropdown:SetList({})
    if db.currentExpansion == 1 then
        for i=1,14 do
            group.DungeonDropdown:AddItem(i,dungeonList[i])
        end
    elseif db.currentExpansion == 2 then
        for i=15,27 do
            group.DungeonDropdown:AddItem(i,dungeonList[i])
        end
    end
	group.DungeonDropdown:SetValue(db.currentDungeonIdx)
	group.SublevelDropdown:SetList(dungeonSubLevels[db.currentDungeonIdx])
	group.SublevelDropdown:SetValue(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel)
    group.DungeonDropdown:ClearFocus()
    group.SublevelDropdown:ClearFocus()
end

---CreateDungeonSelectDropdown
---Creates both dungeon and sublevel dropdowns
function MethodDungeonTools:CreateDungeonSelectDropdown(frame)
	--Simple Group to hold both dropdowns
	frame.DungeonSelectionGroup = AceGUI:Create("SimpleGroup")
	local group = frame.DungeonSelectionGroup
    group.frame:SetFrameStrata("HIGH")
    group.frame:SetFrameLevel(50)
	group:SetWidth(200)
	group:SetHeight(50)
	group:SetPoint("TOPLEFT",frame.topPanel,"BOTTOMLEFT",0,2)
    group:SetLayout("List")

    MethodDungeonTools:FixAceGUIShowHide(group)

    --dungeon select
	group.DungeonDropdown = AceGUI:Create("Dropdown")
	group.DungeonDropdown.text:SetJustifyH("LEFT")
	group.DungeonDropdown:SetCallback("OnValueChanged",function(widget,callbackName,key)
		if key==14 or key == 27 then
            db.currentExpansion = (db.currentExpansion%2)+1
            db.currentDungeonIdx = key==14 and 15 or 1
            MethodDungeonTools:UpdateDungeonDropDown()
            MethodDungeonTools:UpdateToDungeon(db.currentDungeonIdx)
		else
            MethodDungeonTools:UpdateToDungeon(key)
		end
	end)
	group:AddChild(group.DungeonDropdown)

	--sublevel select
	group.SublevelDropdown = AceGUI:Create("Dropdown")
	group.SublevelDropdown.text:SetJustifyH("LEFT")
	group.SublevelDropdown:SetCallback("OnValueChanged",function(widget,callbackName,key)
		db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel = key
		MethodDungeonTools:UpdateMap()
        MethodDungeonTools:ZoomMapToDefault()
	end)
	group:AddChild(group.SublevelDropdown)

	MethodDungeonTools:UpdateDungeonDropDown()
end

---EnsureDBTables
---Makes sure profiles are valid and have their fields set
function MethodDungeonTools:EnsureDBTables()
    --dungeonIdx doesnt exist
    if not dungeonList[db.currentDungeonIdx] or string.find(dungeonList[db.currentDungeonIdx],">") then
        db.currentDungeonIdx = db.currentExpansion == 1 and 1 or db.currentExpansion == 2 and 15
    end
    local preset = MethodDungeonTools:GetCurrentPreset()
    preset.week = preset.week or MethodDungeonTools:GetCurrentAffixWeek()
	db.currentPreset[db.currentDungeonIdx] = db.currentPreset[db.currentDungeonIdx] or 1
    db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentDungeonIdx = db.currentDungeonIdx
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel or 1
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull or 1
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls or {}
    -- make sure, that at least 1 pull exists
    if #db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls == 0 then
        db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[1] = {}
    end

    -- Set current pull to last pull, if the actual current pull does not exists anymore
    if not db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull] then
        db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentPull = #db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls
    end

	for k,v in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls) do
		if k ==0  then
			db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[0] = nil
			break
		end
	end

    --removed clones: remove data from presets
    for pullIdx,pull in pairs(preset.value.pulls) do
        for enemyIdx,clones in pairs(pull) do

            if tonumber(enemyIdx) then
                --enemy does not exist at all anymore
                if not MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx] then
                    pull[enemyIdx] = nil
                else
                    --only clones
                    for k,v in pairs(clones) do
                        if not MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][v] then
                            clones[k] = nil
                        end
                    end
                end
            end
        end
        pull["color"] = pull["color"] or db.defaultColor
    end

    MethodDungeonTools:GetCurrentPreset().week = MethodDungeonTools:GetCurrentPreset().week or MethodDungeonTools:GetCurrentAffixWeek()

    if db.currentDungeonIdx == 19 then
        local englishFaction = UnitFactionGroup("player")
        preset.faction  = preset.faction or (englishFaction and englishFaction=="Alliance") and 2 or 1
    end

    if db.currentDungeonIdx == 16 and (not preset.freeholdCrewSelected) then
        local week = preset.week
        week = week%3
        if week == 0 then week = 3 end
        preset.freeholdCrew = week
        preset.freeholdCrewSelected = true
    end

    db.MDI = db.MDI or {}
    preset.mdi = preset.mdi or {}
    preset.mdi.freehold = preset.mdi.freehold or 1
    preset.mdi.freeholdJoined = preset.mdi.freeholdJoined or false
    preset.mdi.beguiling = preset.mdi.beguiling or 1
    preset.difficulty = preset.difficulty or db.currentDifficulty
    preset.mdiEnabled = preset.mdiEnabled or db.MDI.enabled

    --make sure sublevel actually exists for the dungeon
    --this might have been caused by bugged dropdowns in the past
    local maxSublevel = -1
    for _,_ in pairs(MethodDungeonTools.dungeonMaps[db.currentDungeonIdx]) do
        maxSublevel = maxSublevel + 1
    end
    if preset.value.currentSublevel > maxSublevel then preset.value.currentSublevel = maxSublevel end
    --make sure teeeming flag is set
    preset.value.teeming = MethodDungeonTools:IsWeekTeeming(preset.week)
end

function MethodDungeonTools:GetTileFormat(dungeonIdx)
    local mapInfo = MethodDungeonTools.mapInfo[dungeonIdx]
    return mapInfo and mapInfo.tileFormat or 4
end

function MethodDungeonTools:UpdateMap(ignoreSetSelection,ignoreReloadPullButtons,ignoreUpdateProgressBar)
	local mapName
	local frame = MethodDungeonTools.main_frame
	mapName = MethodDungeonTools.dungeonMaps[db.currentDungeonIdx][0]
	MethodDungeonTools:EnsureDBTables()
    local preset = MethodDungeonTools:GetCurrentPreset()
    if preset.difficulty then
        db.currentDifficulty = preset.difficulty
        frame.sidePanel.DifficultySlider:SetValue(db.currentDifficulty)
        frame.sidePanel.difficultyWarning:Toggle(db.currentDifficulty)
    end
	local fileName = MethodDungeonTools.dungeonMaps[db.currentDungeonIdx][preset.value.currentSublevel]
	local path = "Interface\\WorldMap\\"..mapName.."\\"
    local tileFormat = MethodDungeonTools:GetTileFormat(db.currentDungeonIdx)
	for i=1,12 do
        if tileFormat == 4 then
            local texName = path..fileName..i
            if frame["mapPanelTile"..i] then
                frame["mapPanelTile"..i]:SetTexture(texName)
                frame["mapPanelTile"..i]:Show()
            end
        else
            if frame["mapPanelTile"..i] then
                frame["mapPanelTile"..i]:Hide()
            end
        end
	end
    for i=1,10 do
        for j=1,15 do
            if tileFormat == 15 then
                local texName= path..fileName..((i - 1) * 15 + j)
                frame["largeMapPanelTile"..i..j]:SetTexture(texName)
                frame["largeMapPanelTile"..i..j]:Show()
            else
                frame["largeMapPanelTile"..i..j]:Hide()
            end
        end
    end
	MethodDungeonTools:UpdateDungeonEnemies()
    MethodDungeonTools:DungeonEnemies_UpdateTeeming()
    MethodDungeonTools:DungeonEnemies_UpdateSeasonalAffix()

	if not ignoreReloadPullButtons then
		MethodDungeonTools:ReloadPullButtons()
	end
	--handle delete button disable/enable
	local presetCount = 0
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		presetCount = presetCount + 1
	end
	if (db.currentPreset[db.currentDungeonIdx] == 1 or db.currentPreset[db.currentDungeonIdx] == presetCount) or MethodDungeonTools.liveSessionActive then
		MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(true)
		MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(0.5,0.5,0.5)
	else
		MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
		MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(1,0.8196,0)
	end
    --live mode
    local livePreset = MethodDungeonTools:GetCurrentLivePreset()
    if MethodDungeonTools.liveSessionActive and preset ~= livePreset then
        MethodDungeonTools.main_frame.liveReturnButton:Show()
        MethodDungeonTools.main_frame.setLivePresetButton:Show()
    else
        MethodDungeonTools.main_frame.liveReturnButton:Hide()
        MethodDungeonTools.main_frame.setLivePresetButton:Hide()
    end
    MethodDungeonTools:UpdatePresetDropdownTextColor()

	if not ignoreSetSelection then MethodDungeonTools:SetSelectionToPull(preset.value.currentPull) end
	MethodDungeonTools:UpdateDungeonDropDown()
    --frame.sidePanel.affixDropdown:SetAffixWeek(MethodDungeonTools:GetCurrentPreset().week,ignoreReloadPullButtons,ignoreUpdateProgressBar)
    frame.sidePanel.affixDropdown:SetValue(MethodDungeonTools:GetCurrentPreset().week)
    MethodDungeonTools:ToggleFreeholdSelector(db.currentDungeonIdx == 16)
    MethodDungeonTools:ToggleBoralusSelector(db.currentDungeonIdx == 19)
    MethodDungeonTools:DisplayMDISelector()
    MethodDungeonTools:DrawAllPresetObjects()
    MethodDungeonTools:KillAllAnimatedLines()
    MethodDungeonTools:DrawAllAnimatedLines()
end

---UpdateToDungeon
---Updates the map to the specified dungeon
function MethodDungeonTools:UpdateToDungeon(dungeonIdx,ignoreUpdateMap,init)
    if db.currentExpansion == 1 then
        if dungeonIdx>=15 then
            db.currentExpansion = 2
        end
    elseif db.currentExpansion == 2 then
        if dungeonIdx<=14 then
            db.currentExpansion = 1
        end
    end
    db.currentDungeonIdx = dungeonIdx
	if not db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel then db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel=1 end
    if init then return end
	MethodDungeonTools:UpdatePresetDropDown()
	if not ignoreUpdateMap then MethodDungeonTools:UpdateMap() end
    MethodDungeonTools:ZoomMapToDefault()
     --Colors the first pull in "Default" presets
    if db.currentPreset[db.currentDungeonIdx] == 1 then MethodDungeonTools:ColorPull() end
end

function MethodDungeonTools:DeletePreset(index)
	tremove(db.presets[db.currentDungeonIdx],index)
	db.currentPreset[db.currentDungeonIdx] = index-1
	MethodDungeonTools:UpdatePresetDropDown()
	MethodDungeonTools:UpdateMap()
    MethodDungeonTools:ZoomMapToDefault()
end

local zoneIdToDungeonIdx = {
    [934] = 15,--atal
    [935] = 15,--atal
    [936] = 16,--fh
    [1004] = 17,--kr
    [1039] = 18,--shrine
    [1040] = 18,--shrine
    [1162] = 19,--siege
    [1038] = 20,--temple
    [1043] = 20,--temple
    [1010] = 21,--motherlode
    [1041] = 22,--underrot
    [1042] = 22,--underrot
    [974] = 23,--toldagor
    [975] = 23,--toldagor
    [976] = 23,--toldagor
    [977] = 23,--toldagor
    [978] = 23,--toldagor
    [979] = 23,--toldagor
    [980] = 23,--toldagor
    [1015] = 24,--wcm
    [1016] = 24,--wcm
    [1017] = 24,--wcm
    [1018] = 24,--wcm
    [1029] = 24,--wcm
    [1490] = 25,--lower mecha
    [1491] = 26,--upper mecha
    [1493] = 26,--upper mecha
    [1494] = 26,--upper mecha
    [1497] = 26,--upper mecha
}
local lastUpdatedDungeonIdx
function MethodDungeonTools:CheckCurrentZone(init)
    local zoneId = C_Map.GetBestMapForUnit("player")
    local dungeonIdx = zoneIdToDungeonIdx[zoneId]
    if dungeonIdx and (not lastUpdatedDungeonIdx or  dungeonIdx ~= lastUpdatedDungeonIdx) then
        lastUpdatedDungeonIdx = dungeonIdx
        MethodDungeonTools:UpdateToDungeon(dungeonIdx,nil,init)
    end
end

---CountPresets
---Counts the number of presets of the current dungeon
function MethodDungeonTools:CountPresets()
    return #db.presets[db.currentDungeonIdx]-2
end

---DeleteAllPresets
---Deletes all presets from the current dungeon
function MethodDungeonTools:DeleteAllPresets()
    local countPresets = #db.presets[db.currentDungeonIdx]-1
    for i=countPresets,2,-1 do
        tremove(db.presets[db.currentDungeonIdx],i)
        db.currentPreset[db.currentDungeonIdx] = i-1
    end
    MethodDungeonTools:UpdatePresetDropDown()
    MethodDungeonTools:UpdateMap()
end

function MethodDungeonTools:ClearPreset(preset,silent)
    if preset == self:GetCurrentPreset() then silent = false end
	table.wipe(preset.value.pulls)
	preset.value.currentPull = 1
    table.wipe(preset.value.riftOffsets)
	--MethodDungeonTools:DeleteAllPresetObjects()
    self:EnsureDBTables()
    if not silent then
        self:UpdateMap()
        self:ReloadPullButtons()
    end
    MethodDungeonTools:ColorPull()
end

function MethodDungeonTools:CreateNewPreset(name)
	if name == "<New Preset>" then
		MethodDungeonTools.main_frame.presetCreationLabel:SetText(L"Cannot create preset '"..name.."'")
		MethodDungeonTools.main_frame.presetCreationCreateButton:SetDisabled(true)
		MethodDungeonTools.main_frame.presetCreationCreateButton.text:SetTextColor(0.5,0.5,0.5)
		MethodDungeonTools.main_frame.presetCreationFrame:DoLayout()
		return
	end
	local duplicate = false
	local countPresets = 0
	for k,v in pairs(db.presets[db.currentDungeonIdx]) do
		countPresets = countPresets + 1
		if v.text == name then duplicate = true end
	end
	if duplicate == false then
		db.presets[db.currentDungeonIdx][countPresets+1] = db.presets[db.currentDungeonIdx][countPresets] --put <New Preset> at the end of the list

		local startingPointPresetIdx = MethodDungeonTools.main_frame.PresetCreationDropDown:GetValue()-1
		if startingPointPresetIdx>0 then
			db.presets[db.currentDungeonIdx][countPresets] = MethodDungeonTools:CopyObject(db.presets[db.currentDungeonIdx][startingPointPresetIdx])
			db.presets[db.currentDungeonIdx][countPresets].text = name
			db.presets[db.currentDungeonIdx][countPresets].uid = nil
		else
			db.presets[db.currentDungeonIdx][countPresets] = {text=name,value={}}
		end

		db.currentPreset[db.currentDungeonIdx] = countPresets
		MethodDungeonTools.main_frame.presetCreationFrame:Hide()
		MethodDungeonTools:UpdatePresetDropDown()
		MethodDungeonTools:UpdateMap()
        MethodDungeonTools:ZoomMapToDefault()
        MethodDungeonTools:SetPresetColorPaletteInfo()
        MethodDungeonTools:ColorAllPulls()
	else
		MethodDungeonTools.main_frame.presetCreationLabel:SetText("'"..name..L"' already exists")
		MethodDungeonTools.main_frame.presetCreationCreateButton:SetDisabled(true)
		MethodDungeonTools.main_frame.presetCreationCreateButton.text:SetTextColor(0.5,0.5,0.5)
		MethodDungeonTools.main_frame.presetCreationFrame:DoLayout()
	end
end



function MethodDungeonTools:SanitizePresetName(text)
	--check if name is valid, block button if so, unblock if valid
	if text == "<New Preset>" then
		return false
	else
		local duplicate = false
		local countPresets = 0
		for k,v in pairs(db.presets[db.currentDungeonIdx]) do
			countPresets = countPresets + 1
			if v.text == text then duplicate = true end
		end
		return not duplicate and text or false
	end
end


function MethodDungeonTools:MakeChatPresetImportFrame(frame)
    frame.chatPresetImportFrame = AceGUI:Create("Frame")
    local chatImport = frame.chatPresetImportFrame
    chatImport:SetTitle(L"Import Preset")
    chatImport:SetWidth(400)
    chatImport:SetHeight(100)
    chatImport:EnableResize(false)
    chatImport:SetLayout("Flow")
    chatImport:SetCallback("OnClose", function(widget)
        MethodDungeonTools:UpdatePresetDropDown()
        if db.currentPreset[db.currentDungeonIdx] ~= 1 then
            MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
            MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(1,0.8196,0)
        end
    end)
    chatImport.defaultText = "Import Preset:\n"
    chatImport.importLabel = AceGUI:Create("Label")
    chatImport.importLabel:SetText(chatImport.defaultText)
    chatImport.importLabel:SetWidth(250)
    --chatImport.importLabel:SetColor(1,0,0)

    chatImport.importButton = AceGUI:Create("Button")
    local importButton = chatImport.importButton
    importButton:SetText(L"Import")
    importButton:SetWidth(100)
    importButton:SetCallback("OnClick", function()
        local newPreset = chatImport.currentPreset
        if MethodDungeonTools:ValidateImportPreset(newPreset) then
            chatImport:Hide()
            MethodDungeonTools:ImportPreset(MethodDungeonTools:DeepCopy(newPreset))
        else
            print("MDT: Error importing preset report to author")
        end
    end)
    chatImport:AddChild(chatImport.importLabel)
    chatImport:AddChild(importButton)
    chatImport:Hide()

end

function MethodDungeonTools:OpenChatImportPresetDialog(sender,preset,live)
    MethodDungeonTools:HideAllDialogs()
    local chatImport = MethodDungeonTools.main_frame.chatPresetImportFrame
    chatImport:ClearAllPoints()
    chatImport:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
    chatImport.currentPreset = preset
    local dungeon = MethodDungeonTools:GetDungeonName(preset.value.currentDungeonIdx)
    local name = preset.text
    chatImport:Show()
    chatImport.importLabel:SetText(chatImport.defaultText..sender.. ": "..dungeon.." - "..name)
    chatImport:SetTitle("Import Preset")
    chatImport.importButton:SetText("Import")
    chatImport.live = nil
    if live then
        chatImport.importLabel:SetText("Join Live Session:\n"..sender.. ": "..dungeon.." - "..name)
        chatImport:SetTitle("Live Session")
        chatImport.importButton:SetText("Join")
        chatImport.live = true
    end
end

function MethodDungeonTools:MakePresetImportFrame(frame)
	frame.presetImportFrame = AceGUI:Create("Frame")
	frame.presetImportFrame:SetTitle(L"Import Preset")
	frame.presetImportFrame:SetWidth(400)
	frame.presetImportFrame:SetHeight(200)
	frame.presetImportFrame:EnableResize(false)
	frame.presetImportFrame:SetLayout("Flow")
	frame.presetImportFrame:SetCallback("OnClose", function(widget)
		MethodDungeonTools:UpdatePresetDropDown()
		if db.currentPreset[db.currentDungeonIdx] ~= 1 then
			MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
			MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(1,0.8196,0)
		end
	end)

	frame.presetImportLabel = AceGUI:Create("Label")
	frame.presetImportLabel:SetText(nil)
	frame.presetImportLabel:SetWidth(390)
    frame.presetImportLabel:SetHeight(20)
	frame.presetImportLabel:SetColor(1,0,0)

	local importString	= ""
	frame.presetImportBox = AceGUI:Create("EditBox")
	frame.presetImportBox:SetLabel(L"Import Preset:")
	frame.presetImportBox:SetWidth(255)
	frame.presetImportBox:SetCallback("OnEnterPressed", function(widget, event, text) importString = text end)
	frame.presetImportFrame:AddChild(frame.presetImportBox)

	local importButton = AceGUI:Create("Button")
	importButton:SetText(L"Import")
	importButton:SetWidth(100)
	importButton:SetCallback("OnClick", function()
		local newPreset = MethodDungeonTools:StringToTable(importString, true)
		if MethodDungeonTools:ValidateImportPreset(newPreset) then
			MethodDungeonTools.main_frame.presetImportFrame:Hide()
			MethodDungeonTools:ImportPreset(newPreset)
            if db.colorPaletteInfo.forceColorBlindMode then
                MethodDungeonTools:ColorAllPulls()
            end

		else
			frame.presetImportLabel:SetText(L"Invalid import string")
		end
	end)
	frame.presetImportFrame:AddChild(importButton)
	frame.presetImportFrame:AddChild(frame.presetImportLabel)

    frame.wagoLabel = AceGUI:Create("InteractiveLabel")
    frame.wagoLabel:SetText(" >> 点击复制wago.io网址 << ")
    frame.wagoLabel:SetFont(ChatFontNormal:GetFont(), 13, "")
    frame.wagoLabel:SetWidth(390)
    frame.wagoLabel:SetHeight(20)
    frame.wagoLabel:SetColor(1,1,0)
    frame.wagoLabel.frame.tooltipLines = "说明`wago.io是分享WA,MDT等字符串的国外网站，点击这里可以得到对应副本的预案列表地址，请复制到浏览器中打开。" ..
    "`然后打开某个分享的预案后，点击右上角的'COPY MDT IMPORT STRING'就可以导入进来了` `注意：`  繁盛词缀是标有'Teeming'的`  自由镇的预案分三种任务`  围攻的预案分联盟和部落"
    frame.wagoLabel:SetCallback("OnEnter", function(self)
        CoreUIShowTooltip(self.frame)
    end)
    frame.wagoLabel:SetCallback("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.wagoLabel:SetCallback("OnClick", function()
        local prefix = "https://wago.io/mdt/pve/dungeons/"
        local mapping = {
            ["Atal'Dazar"] = "atal-dazar",
            ["Freehold"] = "freehold",
            ["Kings' Rest"] = "kings-rest",
            ["Shrine of the Storm"] = "shrine-of-the-storm",
            ["Siege of Boralus"] = "siege-of-boralus",
            ["Temple of Sethraliss"] = "temple-of-sethraliss",
            ["The MOTHERLODE!!"] = "the-motherlode",
            ["The Underrot"] = "the-underrot",
            ["Tol Dagor"] = "tol-dagor",
            ["Waycrest Manor"] = "waycrest-manor",
        }
        local lmap = {}
        for k,v in pairs(mapping) do
            lmap[L[k]] = v
        end
        local idx = MethodDungeonTools.main_frame.DungeonSelectionGroup.DungeonDropdown:GetValue()
        if not lmap[dungeonList[idx]] then
            return U1Message("暂时没有副本-" .. dungeonList[idx] .. "-对应的网址")
        end
        local url = prefix .. lmap[dungeonList[idx]]
        local chatFrame = GetCVar("chatStyle")=="im" and SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
        local eb = chatFrame and chatFrame.editBox
        if(eb) then
            eb:Insert(url)
            eb:Show();
            eb:HighlightText()
            eb:SetFocus()
        end
    end)
    frame.presetImportFrame:AddChild(frame.wagoLabel)

	frame.presetImportFrame:Hide()

end

function MethodDungeonTools:MakePresetCreationFrame(frame)
	frame.presetCreationFrame = AceGUI:Create("Frame")
	frame.presetCreationFrame:SetTitle(L"New Preset")
	frame.presetCreationFrame:SetWidth(400)
	frame.presetCreationFrame:SetHeight(200)
	frame.presetCreationFrame:EnableResize(false)
	--frame.presetCreationFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame.presetCreationFrame:SetLayout("Flow")
	frame.presetCreationFrame:SetCallback("OnClose", function(widget)
		MethodDungeonTools:UpdatePresetDropDown()
		if db.currentPreset[db.currentDungeonIdx] ~= 1 then
			MethodDungeonTools.main_frame.sidePanelDeleteButton:SetDisabled(false)
			MethodDungeonTools.main_frame.sidePanelDeleteButton.text:SetTextColor(1,0.8196,0)
		end
	end)


	frame.PresetCreationEditbox = AceGUI:Create("EditBox")
	frame.PresetCreationEditbox:SetLabel(L"Preset name:")
	frame.PresetCreationEditbox:SetWidth(255)
	frame.PresetCreationEditbox:SetCallback("OnEnterPressed", function(widget, event, text)
		--check if name is valid, block button if so, unblock if valid
		if MethodDungeonTools:SanitizePresetName(text) then
			frame.presetCreationLabel:SetText(nil)
			frame.presetCreationCreateButton:SetDisabled(false)
			frame.presetCreationCreateButton.text:SetTextColor(1,0.8196,0)
		else
			frame.presetCreationLabel:SetText(L"Cannot create preset '"..text.."'")
			frame.presetCreationCreateButton:SetDisabled(true)
			frame.presetCreationCreateButton.text:SetTextColor(0.5,0.5,0.5)
		end
		frame.presetCreationFrame:DoLayout()
	end)
	frame.presetCreationFrame:AddChild(frame.PresetCreationEditbox)

	frame.presetCreationCreateButton = AceGUI:Create("Button")
	frame.presetCreationCreateButton:SetText(L"Create")
	frame.presetCreationCreateButton:SetWidth(100)
	frame.presetCreationCreateButton:SetCallback("OnClick", function()
		local name = frame.PresetCreationEditbox:GetText()
		MethodDungeonTools:CreateNewPreset(name)
	end)
	frame.presetCreationFrame:AddChild(frame.presetCreationCreateButton)

	frame.presetCreationLabel = AceGUI:Create("Label")
	frame.presetCreationLabel:SetText(nil)
	frame.presetCreationLabel:SetWidth(390)
	frame.presetCreationLabel:SetColor(1,0,0)
	frame.presetCreationFrame:AddChild(frame.presetCreationLabel)


	frame.PresetCreationDropDown = AceGUI:Create("Dropdown")
	frame.PresetCreationDropDown:SetLabel(L"Use as a starting point:")
	frame.PresetCreationDropDown.text:SetJustifyH("LEFT")
	frame.presetCreationFrame:AddChild(frame.PresetCreationDropDown)

	frame.presetCreationFrame:Hide()
end

function MethodDungeonTools:ValidateImportPreset(preset)
    if type(preset) ~= "table" then return false end
    if not preset.text then return false end
    if not preset.value then return false end
    if type(preset.text) ~= "string" then return false end
    if type(preset.value) ~= "table" then return false end
    if not preset.value.currentDungeonIdx then return false end
    if not preset.value.currentPull then return false end
    if not preset.value.currentSublevel then return false end
    if not preset.value.pulls then return false end
    if type(preset.value.pulls) ~= "table" then return false end
    return true
end

function MethodDungeonTools:ImportPreset(preset,fromLiveSession)
    --change dungeon to dungeon of the new preset
    self:UpdateToDungeon(preset.value.currentDungeonIdx,true)
    local mdiEnabled = preset.mdiEnabled
    --search for uid
    local updateIndex
    local duplicatePreset
    for k,v in pairs(db.presets[db.currentDungeonIdx]) do
        if v.uid and v.uid == preset.uid then
            updateIndex = k
            duplicatePreset = v
            break
        end
    end

    local updateCallback = function()
        if self.main_frame.ConfirmationFrame then
            self.main_frame.ConfirmationFrame:SetCallback("OnClose", function() end)
        end
        db.MDI.enabled = mdiEnabled
        db.presets[db.currentDungeonIdx][updateIndex] = preset
        db.currentPreset[db.currentDungeonIdx] = updateIndex
        self.liveUpdateFrameOpen = nil
        self:UpdatePresetDropDown()
        self:UpdateMap()
        if fromLiveSession then
            self.main_frame.SendingStatusBar:Hide()
            if self.main_frame.LoadingSpinner then
                self.main_frame.LoadingSpinner:Hide()
                self.main_frame.LoadingSpinner.Anim:Stop()
            end
        end
    end
    local copyCallback = function()
        if self.main_frame.ConfirmationFrame then
            self.main_frame.ConfirmationFrame:SetCallback("OnClose", function() end)
        end
        db.MDI.enabled = mdiEnabled
        local name = preset.text
        local num = 2
        for k,v in pairs(db.presets[db.currentDungeonIdx]) do
            if name == v.text then
                name = preset.text.." "..num
                num = num + 1
            end
        end
        preset.text = name
        if fromLiveSession then
            if duplicatePreset then duplicatePreset.uid = nil end
        else
            preset.uid = nil
        end
        local countPresets = 0
        for k,v in pairs(db.presets[db.currentDungeonIdx]) do
            countPresets = countPresets + 1
        end
        db.presets[db.currentDungeonIdx][countPresets+1] = db.presets[db.currentDungeonIdx][countPresets] --put <New Preset> at the end of the list
        db.presets[db.currentDungeonIdx][countPresets] = preset
        db.currentPreset[db.currentDungeonIdx] = countPresets
        self.liveUpdateFrameOpen = nil
        self:UpdatePresetDropDown()
        self:UpdateMap()
        if fromLiveSession then
            self.main_frame.SendingStatusBar:Hide()
            if self.main_frame.LoadingSpinner then
                self.main_frame.LoadingSpinner:Hide()
                self.main_frame.LoadingSpinner.Anim:Stop()
            end
        end
    end
    local closeCallback = function()
        self.liveUpdateFrameOpen = nil
        self:LiveSession_Disable()
        self.main_frame.ConfirmationFrame:SetCallback("OnClose", function() end)
        if fromLiveSession then
            self.main_frame.SendingStatusBar:Hide()
            if self.main_frame.LoadingSpinner then
                self.main_frame.LoadingSpinner:Hide()
                self.main_frame.LoadingSpinner.Anim:Stop()
            end
        end
    end

    --open dialog to ask for replacing
    if updateIndex then
        local prompt = "You have an earlier version of this preset with the name '"..duplicatePreset.text.."'\nDo you wish to update or create a new copy?\n\n\n"
        self:OpenConfirmationFrame(450,150,"Import Preset","Update",prompt, updateCallback,"Copy",copyCallback)
        if fromLiveSession then
            self.liveUpdateFrameOpen = true
            self.main_frame.ConfirmationFrame:SetCallback("OnClose", function()closeCallback() end)
        end
    else
        copyCallback()
    end
end

---Stores r g b values for coloring pulls with MethodDungeonTools:ColorPull()
local colorPaletteValues = {
    [1] = { --Rainbow values
        [1] = {[1]=0.2446, [2]=1, [3]=0.2446},
        [2] = {[1]=0.2446, [2]=1, [3]=0.6223},
        [3] = {[1]=0.2446, [2]=1, [3]=1},
        [4] = {[1]=0.2446, [2]=0.6223, [3]=1},
        [5] = {[1]=0.2446, [2]=0.2446, [3]=1},
        [6] = {[1]=0.6223, [2]=0.6223, [3]=1},
        [7] = {[1]=1, [2]=0.2446, [3]=1},
        [8] = {[1]=1, [2]=0.2446, [3]=0.6223},
        [9] = {[1]=1, [2]=0.2446, [3]=0.2446},
        [10] = {[1]=1, [2]=0.60971, [3]=0.2446},
        [11] = {[1]=1, [2]=0.98741, [3]=0.2446},
        [12] = {[1]=0.63489, [2]=1, [3]=0.2446},
        --[13] = {[1]=1, [2]=0.2446, [3]=0.54676},
        --[14] = {[1]=1, [2]=0.2446, [3]=0.32014},
        --[15] = {[1]=1, [2]=0.38309, [3]=0.2446},
        --[16] = {[1]=1, [2]=0.60971, [3]=0.2446},
        --[17] = {[1]=1, [2]=0.83633, [3]=0.2446},
        --[18] = {[1]=0.93705, [2]=1, [3]=0.2446},
        --[19] = {[1]=0.71043, [2]=1, [3]=0.2446},
        --[20] = {[1]=0.48381, [2]=1, [3]=0.2446},
    },
    [2] = { --Black and Yellow values
        [1] = {[1]=0.4, [2]=0.4, [3]=0.4},
        [2] = {[1]=1, [2]=1, [3]=0.0},
    },
    [3] = { --Red, Green and Blue values
        [1] = {[1]=0.85882, [2]=0.058824, [3]=0.15294},
        [2] = {[1]=0.49804, [2]=1.0, [3]=0.0},
        [3] = {[1]=0.0, [2]=0.50196, [3]=1.0},
    },
    [4] = { --High Contrast values
        [1] = {[1]=1, [2]=0.2446, [3]=1},
        [2] = {[1]=0.2446, [2]=1, [3]=0.6223},
        [3] = {[1]=1, [2]=0.2446, [3]=0.2446},
        [4] = {[1]=0.2446, [2]=0.6223, [3]=1},
        [5] = {[1]=1, [2]=0.98741, [3]=0.2446},
        [6] = {[1]=0.2446, [2]=1, [3]=0.2446},
        [7] = {[1]=1, [2]=0.2446, [3]=0.6223},
        [8] = {[1]=0.2446, [2]=1, [3]=1},
        [9] = {[1]=1, [2]=0.60971, [3]=0.2446},
        [10] = {[1]=0.2446, [2]=0.2446, [3]=1},
        [11] = {[1]=0.63489, [2]=1, [3]=0.2446},
    },
    [5] = { --Color Blind Friendly values (Based on IBM's color library "Color blind safe"
        [1] = {[1]=0.39215686274509803, [2]=0.5607843137254902, [3]=1.0},
        --[2] = {[1]=0.47058823529411764, [2]=0.3686274509803922, [3]=0.9411764705882353},
        [2] = {[1]=0.8627450980392157, [2]=0.14901960784313725, [3]=0.4980392156862745},
        [3] = {[1]=0.996078431372549, [2]=0.3803921568627451, [3]=0.0},
        [4] = {[1]=1.0, [2]=0.6901960784313725, [3]=0.0},
        },

}

---Dropdown menu items for color settings frame
local colorPaletteNames = {
        [1] = "Rainbow",
        [2] = "Black and Yellow",
        [3] = "Red, Green and Blue",
        [4] = "High Contrast",
        [5] = "Color Blind Friendly",
        [6] = "Custom",
}

---SetPresetColorPaletteInfo
---Saves currently selected automatic coloring settings to the current
---This can be achieved easier, but it will increase the export text length significantly for non custom palettes.
function MethodDungeonTools:SetPresetColorPaletteInfo()
    local preset = MethodDungeonTools:GetCurrentPreset()
    preset.colorPaletteInfo = {}
    preset.colorPaletteInfo.autoColoring = db.colorPaletteInfo.autoColoring
    if preset.colorPaletteInfo.autoColoring then
        preset.colorPaletteInfo.colorPaletteIdx = db.colorPaletteInfo.colorPaletteIdx
        if preset.colorPaletteInfo.colorPaletteIdx == 6 then
            preset.colorPaletteInfo.customPaletteValues = db.colorPaletteInfo.customPaletteValues
            preset.colorPaletteInfo.numberCustomColors = db.colorPaletteInfo.numberCustomColors
        end
    end
    --Code below works, but in most cases it saves more data to the preset and thereby significantly increases the export string length
    --MethodDungeonTools:GetCurrentPreset().colorPaletteInfo = db.colorPaletteInfo
end

---GetPresetColorPaletteInfo
function MethodDungeonTools:GetPresetColorPaletteInfo(preset)
    preset = preset or MethodDungeonTools:GetCurrentPreset()
    return preset.colorPaletteInfo
end

---ColorPull
---Function executes full coloring of a pull and it's blips
function MethodDungeonTools:ColorPull(colorValues, pullIdx, preset, bypass, exportColorBlind) -- bypass can be passed as true to color even when automatic coloring is toggled off
    local colorPaletteInfo = MethodDungeonTools:GetPresetColorPaletteInfo(preset)
    local pullIdx = pullIdx or MethodDungeonTools:GetCurrentPull()
    local colorValues
    local numberColors
    local r,g,b
    if colorPaletteInfo.autoColoring or bypass == true then
        --Force color blind mode locally, will not alter the color values saved to a preset
        if db.colorPaletteInfo.forceColorBlindMode == true and not exportColorBlind then
            --Local color blind mode, will not alter the colorPaletteInfo saved to a preset
            colorValues = colorValues or colorPaletteValues[colorValues] or colorPaletteValues[5]
            numberColors = #colorValues
        else
            --Regular coloring
            colorValues = colorValues or colorPaletteValues[colorValues] or colorPaletteInfo.colorPaletteIdx == 6 and colorPaletteInfo.customPaletteValues or colorPaletteValues[colorPaletteInfo.colorPaletteIdx]
            numberColors = colorPaletteInfo.colorPaletteIdx == 6 and colorPaletteInfo.numberCustomColors or #colorValues  -- tables must start from 1 and have no blank rows
        end
        local colorIdx = (pullIdx-1)%numberColors+1
        r,g,b = colorValues[colorIdx][1],colorValues[colorIdx][2],colorValues[colorIdx][3]

        MethodDungeonTools:DungeonEnemies_SetPullColor(pullIdx,r,g,b)
        MethodDungeonTools:UpdatePullButtonColor(pullIdx,r,g,b)
        MethodDungeonTools:DungeonEnemies_UpdateBlipColors(pullIdx,r,g,b)
    end
end

---ColorAllPulls
---Loops over all pulls in a preset and colors them
function MethodDungeonTools:ColorAllPulls(colorValues, startFrom, bypass, exportColorBlind)
    local preset = self:GetCurrentPreset()
    local startFrom = startFrom or 0
    for pullIdx,_ in pairs(preset.value.pulls) do
        if pullIdx >= startFrom then
            MethodDungeonTools:ColorPull(colorValues, pullIdx, preset, bypass, exportColorBlind)
        end
    end
end

---MakeCustomColorFrame
---creates frame housing settings for user customized color palette
function MethodDungeonTools:MakeCustomColorFrame(frame)
    --Base frame for custom palette setup
    frame.CustomColorFrame = AceGUI:Create("Frame")
    frame.CustomColorFrame:SetTitle("Custom Color Palette")
	frame.CustomColorFrame:SetWidth(290)
	frame.CustomColorFrame:SetHeight(220)
	frame.CustomColorFrame:EnableResize(false)
	frame.CustomColorFrame:SetLayout("Flow")
    frame:AddChild(frame.CustomColorFrame)

    --Slider to adjust number of different colors and remake the frame OnMouseUp
    frame.CustomColorFrame.ColorSlider = AceGUI:Create("Slider")
    frame.CustomColorFrame.ColorSlider:SetSliderValues(2,20,1)
    frame.CustomColorFrame.ColorSlider:SetValue(db.colorPaletteInfo.numberCustomColors)
    frame.CustomColorFrame.ColorSlider:SetLabel("Choose number of colors")
    frame.CustomColorFrame.ColorSlider:SetRelativeWidth(1)
    frame.CustomColorFrame.ColorSlider:SetCallback("OnMouseUp", function(event, callbackName, value)
        if value>20 then
            db.colorPaletteInfo.numberCustomColors = 20
        elseif value<2 then
            db.colorPaletteInfo.numberCustomColors = 2
        else
            db.colorPaletteInfo.numberCustomColors = value
        end
        MethodDungeonTools:SetPresetColorPaletteInfo()
        MethodDungeonTools:ColorAllPulls()
        frame.CustomColorFrame:ReleaseChildren()
        frame.CustomColorFrame:Release()
        MethodDungeonTools:MakeCustomColorFrame(frame)
        MethodDungeonTools:OpenCustomColorsDialog()
    end)
    frame.CustomColorFrame:AddChild(frame.CustomColorFrame.ColorSlider)

    --Loop to create as many colorpickers as requested limited by db.colorPaletteInfo.numberCustomColors
    local ColorPicker = {}
    for i= 1,db.colorPaletteInfo.numberCustomColors do
        ColorPicker[i] = AceGUI:Create("ColorPicker")
        if db.colorPaletteInfo.customPaletteValues[i] then
            ColorPicker[i]:SetColor(db.colorPaletteInfo.customPaletteValues[i][1], db.colorPaletteInfo.customPaletteValues[i][2], db.colorPaletteInfo.customPaletteValues[i][3])
        else
            db.colorPaletteInfo.customPaletteValues[i] = {1,1,1}
            ColorPicker[i]:SetColor(db.colorPaletteInfo.customPaletteValues[i][1], db.colorPaletteInfo.customPaletteValues[i][2], db.colorPaletteInfo.customPaletteValues[i][3])
        end
        ColorPicker[i]:SetLabel(" "..i)
        ColorPicker[i]:SetRelativeWidth(0.25)
        ColorPicker[i]:SetHeight(15)
        ColorPicker[i]:SetCallback("OnValueConfirmed", function(widget, event, r, g, b)
                db.colorPaletteInfo.customPaletteValues[i] = {r,g,b}
                MethodDungeonTools:SetPresetColorPaletteInfo()
                MethodDungeonTools:ColorAllPulls()
            end)
        frame.CustomColorFrame:AddChild(ColorPicker[i])
    end
    frame.CustomColorFrame:Hide()
end

function MethodDungeonTools:MakeAutomaticColorsFrame(frame)
	frame.automaticColorsFrame = AceGUI:Create("Frame")
	frame.automaticColorsFrame:SetTitle("Automatic Coloring")
	frame.automaticColorsFrame:SetWidth(240)
	frame.automaticColorsFrame:SetHeight(220)
	frame.automaticColorsFrame:EnableResize(false)
	frame.automaticColorsFrame:SetLayout("Flow")

	frame.AutomaticColorsCheck = AceGUI:Create("CheckBox")
	frame.AutomaticColorsCheck:SetLabel("Automatically color pulls")
	frame.AutomaticColorsCheck:SetValue(db.colorPaletteInfo.autoColoring)
    frame.AutomaticColorsCheck:SetCallback("OnValueChanged",function(widget,callbackName,value)
		db.colorPaletteInfo.autoColoring = value
        MethodDungeonTools:SetPresetColorPaletteInfo()
        frame.AutomaticColorsCheckSidePanel:SetValue(db.colorPaletteInfo.autoColoring)
        if value == true then
            frame.toggleForceColorBlindMode:SetDisabled(false)
            MethodDungeonTools:ColorAllPulls()
        else
            frame.toggleForceColorBlindMode:SetDisabled(true)
        end
	end)
    frame.automaticColorsFrame:AddChild(frame.AutomaticColorsCheck)

    --Toggle local color blind mode
    frame.toggleForceColorBlindMode = AceGUI:Create("CheckBox")
    frame.toggleForceColorBlindMode:SetLabel("Local color blind mode")
    frame.toggleForceColorBlindMode:SetValue(db.colorPaletteInfo.forceColorBlindMode)
    frame.toggleForceColorBlindMode:SetCallback("OnValueChanged",function(widget,callbackName,value)
		db.colorPaletteInfo.forceColorBlindMode = value
        MethodDungeonTools:SetPresetColorPaletteInfo()
        MethodDungeonTools:ColorAllPulls()

	end)
    frame.automaticColorsFrame:AddChild(frame.toggleForceColorBlindMode)

    frame.PaletteSelectDropdown = AceGUI:Create("Dropdown")
    frame.PaletteSelectDropdown:SetList(colorPaletteNames)
    frame.PaletteSelectDropdown:SetLabel("Choose preferred color palette")
    frame.PaletteSelectDropdown:SetValue(db.colorPaletteInfo.colorPaletteIdx)
    frame.PaletteSelectDropdown:SetCallback("OnValueChanged", function(widget,callbackName,value)
        if value == 6 then
            db.colorPaletteInfo.colorPaletteIdx = value
            MethodDungeonTools:OpenCustomColorsDialog()
            MethodDungeonTools:SetPresetColorPaletteInfo()
            MethodDungeonTools:ColorAllPulls()
        else
            MethodDungeonTools.main_frame.automaticColorsFrame.CustomColorFrame:Hide()
            db.colorPaletteInfo.colorPaletteIdx = value
            MethodDungeonTools:SetPresetColorPaletteInfo()
            MethodDungeonTools:ColorAllPulls()
        end
    end)
    frame.automaticColorsFrame:AddChild(frame.PaletteSelectDropdown)

    -- The reason this button exists is to allow altering colorPaletteInfo of an imported preset
    -- Without the need to untoggle/toggle or swap back and forth in the PaletteSelectDropdown
    frame.button = AceGUI:Create("Button")
    frame.button:SetText("Apply to preset")
    frame.button:SetCallback("OnClick", function(widget, callbackName)
        if not db.colorPaletteInfo.autoColoring then
            db.colorPaletteInfo.autoColoring = true
            frame.AutomaticColorsCheck:SetValue(db.colorPaletteInfo.autoColoring)
            frame.AutomaticColorsCheckSidePanel:SetValue(db.colorPaletteInfo.autoColoring)
            frame.toggleForceColorBlindMode:SetDisabled(false)
        end
        MethodDungeonTools:SetPresetColorPaletteInfo()
        MethodDungeonTools:ColorAllPulls()
    end)
    frame.automaticColorsFrame:AddChild(frame.button)

	frame.automaticColorsFrame:Hide()
end

function MethodDungeonTools:MakePullSelectionButtons(frame)
    frame.PullButtonScrollGroup = AceGUI:Create("SimpleGroup")
    frame.PullButtonScrollGroup:SetWidth(248)
    frame.PullButtonScrollGroup:SetHeight(410)
    frame.PullButtonScrollGroup:SetPoint("TOPLEFT",frame.WidgetGroup.frame,"BOTTOMLEFT",-4,-32)
    frame.PullButtonScrollGroup:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,30)
    frame.PullButtonScrollGroup:SetLayout("Fill")
    frame.PullButtonScrollGroup.frame:SetFrameStrata(mainFrameStrata)
    frame.PullButtonScrollGroup.frame:SetBackdropColor(1,1,1,0)
    frame.PullButtonScrollGroup.frame:Show()

    self:FixAceGUIShowHide(frame.PullButtonScrollGroup)

    frame.pullButtonsScrollFrame = AceGUI:Create("ScrollFrame")
    frame.pullButtonsScrollFrame:SetLayout("Flow")

    frame.PullButtonScrollGroup:AddChild(frame.pullButtonsScrollFrame)

    frame.newPullButtons = {}
	--rightclick context menu
    frame.optionsDropDown = L_Create_UIDropDownMenu("PullButtonsOptionsDropDown", nil)
end


function MethodDungeonTools:PresetsAddPull(index, data,preset)
    preset = preset or self:GetCurrentPreset()
    if not data then data = {} end
	if index then
		tinsert(preset.value.pulls,index,data)
	else
		tinsert(preset.value.pulls,data)
	end
    self:EnsureDBTables()
end

---MethodDungeonTools:PresetsMergePulls
---Merges a list of pulls and inserts them at a specified destination.
---
---@param pulls table List of all pull indices, that shall be merged (and deleted). If pulls
---                   is a number, then the pull list is automatically generated from pulls
---                   and destination.
---@param destination number The pull index, where the merged pull shall be inserted.
---
---@author Dradux
function MethodDungeonTools:PresetsMergePulls(pulls, destination)
    if type(pulls) == "number" then
        pulls = {pulls, destination}
    end

    if not destination then
        destination = pulls[#pulls]
    end

    local count_if = self.U.count_if

    local newPull = {}
    local removed_pulls = {}

    for _, pullIdx in ipairs(pulls) do
        local offset = count_if(removed_pulls, function(entry)
            return entry < pullIdx
        end)

        local index = pullIdx - offset
        local pull = self:GetCurrentPreset().value.pulls[index]

        for enemyIdx,clones in pairs(pull) do
            if string.match(enemyIdx, "^%d+$") then
                -- it's really an enemy index
                if tonumber(enemyIdx) then
                    if not newPull[enemyIdx] then
                        newPull[enemyIdx] = clones
                    else
                        for k,v in pairs(clones) do
                            if newPull[enemyIdx][k] ~= nil then
                                local newIndex = #newPull[enemyIdx] + 1
                                newPull[enemyIdx][newIndex] = v
                            else
                                newPull[enemyIdx][k] = v
                            end

                        end
                    end
                end
            else
                -- it's another pull option like color
                local optionName = enemyIdx
                local optionValue = clones
                newPull[optionName] = optionValue
            end
        end

        self:PresetsDeletePull(index)
        tinsert(removed_pulls, pullIdx)
    end

    local offset = count_if(removed_pulls, function(entry)
        return entry < destination
    end)

    local index = destination - offset
    self:PresetsAddPull(index, newPull)
    return index
end

function MethodDungeonTools:PresetsDeletePull(p,preset)
    preset = preset or self:GetCurrentPreset()
    if p == preset.value.currentPull then
        preset.value.currentPull = math.max(p - 1, 1)
    end
	tremove(preset.value.pulls,p)
end

function MethodDungeonTools:GetPulls(preset)
    preset = preset or self:GetCurrentPreset()
    return preset.value.pulls
end

function MethodDungeonTools:GetPullsNum(preset)
    preset = preset or self:GetCurrentPreset()
    return table.getn(preset.value.pulls)
end

function MethodDungeonTools:CopyObject(obj,seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[self:CopyObject(k, s)] = self:CopyObject(v, s) end
    return res
end

function MethodDungeonTools:PresetsSwapPulls(p1,p2)
	local p1copy = self:CopyObject(self:GetCurrentPreset().value.pulls[p1])
	local p2copy = self:CopyObject(self:GetCurrentPreset().value.pulls[p2])
    self:GetCurrentPreset().value.pulls[p1] = p2copy
    self:GetCurrentPreset().value.pulls[p2] = p1copy
end

function MethodDungeonTools:SetMapSublevel(pull)
	--set map sublevel
	local shouldResetZoom = false
	local lastSubLevel
	for enemyIdx,clones in pairs(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[pull]) do
        if tonumber(enemyIdx) then
            for idx,cloneIdx in pairs(clones) do
                if MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx] then
                    lastSubLevel = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx].sublevel
                end
            end
        end
	end
	if lastSubLevel then
		shouldResetZoom = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel ~= lastSubLevel
		db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.currentSublevel = lastSubLevel
        if shouldResetZoom then
            MethodDungeonTools:UpdateMap(true,true,true)
        end
	end

	MethodDungeonTools:UpdateDungeonDropDown()
    if shouldResetZoom then MethodDungeonTools:ZoomMapToDefault() end
end

function MethodDungeonTools:SetSelectionToPull(pull)
	--if pull is not specified set pull to last pull in preset (for adding new pulls)
	if not pull then
		local count = 0
		for k,v in pairs(MethodDungeonTools:GetCurrentPreset().value.pulls) do
			count = count + 1
		end
		pull = count
	end

	--SaveCurrentPresetPull
    if type(pull) == "number" and pull > 0 then
        MethodDungeonTools:GetCurrentPreset().value.currentPull = pull
        MethodDungeonTools:GetCurrentPreset().value.selection = { pull }
        MethodDungeonTools:PickPullButton(pull)

        MethodDungeonTools:DungeonEnemies_UpdateSelected(pull)
    elseif type(pull) == "table" then
        MethodDungeonTools:GetCurrentPreset().value.currentPull = pull[#pull]
        MethodDungeonTools:GetCurrentPreset().value.selection = pull

        MethodDungeonTools:ClearPullButtonPicks()
        for _, pullIdx in ipairs(MethodDungeonTools:GetSelection()) do
            MethodDungeonTools:PickPullButton(pullIdx, true)
            MethodDungeonTools:DungeonEnemies_UpdateSelected(pullIdx)
        end
    end
end

---UpdatePullButtonNPCData
---Updates the portraits display of a button to show which and how many npcs are selected
function MethodDungeonTools:UpdatePullButtonNPCData(idx)
    if db.devMode then return end
	local preset = MethodDungeonTools:GetCurrentPreset()
	local frame = MethodDungeonTools.main_frame.sidePanel
	local enemyTable = {}
	if preset.value.pulls[idx] then
		local enemyTableIdx = 0
		for enemyIdx,clones in pairs(preset.value.pulls[idx]) do
            if tonumber(enemyIdx) then
                --check if enemy exists, remove if not
                if MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx] then
                    local incremented = false
                    local npcId = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["id"]
                    local name = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["name"]
                    local creatureType = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["creatureType"]
                    local level = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["level"]
                    local baseHealth = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["health"]
                    for k,cloneIdx in pairs(clones) do
                        --check if clone exists, remove if not
                        if MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["clones"][cloneIdx] then
                            if self:IsCloneIncluded(enemyIdx,cloneIdx) then
                                if not incremented then enemyTableIdx = enemyTableIdx + 1 incremented = true end
                                if not enemyTable[enemyTableIdx] then enemyTable[enemyTableIdx] = {} end
                                enemyTable[enemyTableIdx].quantity = enemyTable[enemyTableIdx].quantity or 0
                                enemyTable[enemyTableIdx].npcId = npcId
                                enemyTable[enemyTableIdx].count = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["count"]
                                enemyTable[enemyTableIdx].teemingCount = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["teemingCount"]
                                enemyTable[enemyTableIdx].displayId = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["displayId"]
                                enemyTable[enemyTableIdx].quantity = enemyTable[enemyTableIdx].quantity + 1
                                enemyTable[enemyTableIdx].name = name
                                enemyTable[enemyTableIdx].level = level
                                enemyTable[enemyTableIdx].creatureType = creatureType
                                enemyTable[enemyTableIdx].baseHealth = baseHealth
                                enemyTable[enemyTableIdx].ignoreFortified = MethodDungeonTools.dungeonEnemies[db.currentDungeonIdx][enemyIdx]["ignoreFortified"]
                            end
                        end
                    end
                end
            end
		end
	end
	frame.newPullButtons[idx]:SetNPCData(enemyTable)

    if db.MDI.enabled and preset.mdi.beguiling == 13 then end
    --display reaping icon
    local pullForces = MethodDungeonTools:CountForces(idx,false)
    local totalForcesMax = MethodDungeonTools:IsCurrentPresetTeeming() and MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].teeming or MethodDungeonTools.dungeonTotalCount[db.currentDungeonIdx].normal
    local currentPercent = pullForces/totalForcesMax
    local oldPullForces
    if idx == 1 then
        oldPullForces = 0
    else
        oldPullForces =  MethodDungeonTools:CountForces(idx-1,false)
    end
    local oldPercent = oldPullForces/totalForcesMax
    if (math.floor(currentPercent/0.2)>math.floor(oldPercent/0.2)) and oldPercent<1 and db.MDI.enabled and preset.mdi.beguiling == 13 then
        frame.newPullButtons[idx]:ShowReapingIcon(true,currentPercent,oldPercent)
    else
        frame.newPullButtons[idx]:ShowReapingIcon(false,currentPercent,oldPercent)
    end
end

---ReloadPullButtons
---Reloads all pull buttons in the scroll frame
function MethodDungeonTools:ReloadPullButtons()
	local frame = MethodDungeonTools.main_frame.sidePanel
    if not frame.pullButtonsScrollFrame then return end
	local preset = db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]]
    --store scroll value
    local oldScrollValue = frame.pullButtonsScrollFrame.localstatus.scrollvalue
	--first release all children of the scroll frame
	frame.pullButtonsScrollFrame:ReleaseChildren()
	local maxPulls =  0
	for k,v in pairs(preset.value.pulls) do
		maxPulls = maxPulls + 1
	end
	--add new children to the scrollFrame, the frames are from the widget pool so no memory is wasted
    if not db.devMode then
        local idx = 0
        for k,pull in ipairs(preset.value.pulls) do
            idx = idx+1
            frame.newPullButtons[idx] = AceGUI:Create("MethodDungeonToolsPullButton")
            frame.newPullButtons[idx]:SetMaxPulls(maxPulls)
            frame.newPullButtons[idx]:SetIndex(idx)
            MethodDungeonTools:UpdatePullButtonNPCData(idx)
            frame.newPullButtons[idx]:Initialize()
            frame.newPullButtons[idx]:Enable()
            frame.pullButtonsScrollFrame:AddChild(frame.newPullButtons[idx])
        end
    end
	--add the "new pull" button
	frame.newPullButton = AceGUI:Create("MethodDungeonToolsNewPullButton")
	frame.newPullButton:Initialize()
	frame.newPullButton:Enable()
	frame.pullButtonsScrollFrame:AddChild(frame.newPullButton)
    --set the scroll value back to the old value
    frame.pullButtonsScrollFrame.scrollframe.obj:SetScroll(oldScrollValue)
    frame.pullButtonsScrollFrame.scrollframe.obj:FixScroll()
    if self:GetCurrentPreset().value.currentPull then
        self:PickPullButton(self:GetCurrentPreset().value.currentPull)
    end
end

---ClearPullButtonPicks
---Deselects all pull buttons
function MethodDungeonTools:ClearPullButtonPicks()
	local frame = MethodDungeonTools.main_frame.sidePanel
	for k,v in pairs(frame.newPullButtons) do
		v:ClearPick()
	end
end

---PickPullButton
---Selects the current pull button and deselects all other buttons
function MethodDungeonTools:PickPullButton(idx, keepPicked)
    if db.devMode then return end

    if not keepPicked then
        MethodDungeonTools:ClearPullButtonPicks()
    end
	local frame = MethodDungeonTools.main_frame.sidePanel
    frame.newPullButtons[idx]:Pick()
end

---AddPull
---Creates a new pull in the current preset and calls ReloadPullButtons to reflect the change in the scrollframe
function MethodDungeonTools:AddPull(index)
	MethodDungeonTools:PresetsAddPull(index)
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index)
    MethodDungeonTools:ColorPull()
end

function MethodDungeonTools:SetAutomaticColor(index)
	--if not db.colorPaletteInfo.autoColoring then return end

	local H = (index - 1) * 360 / 12 + 120 --db.automaticColorsNum
	--if db.alternatingColors and index % 2 == 0 then
	--	H = H + 180
	--end

	local V = 1--0.5451
	--if db.brightColors then V = 1 end

	local r, g, b = self:HSVtoRGB(H, 0.7554, V)

	--self:DungeonEnemies_SetPullColor(index, r, g, b)
	--self:UpdatePullButtonColor(index, r, g, b)
	--self:DungeonEnemies_UpdateBlipColors(index, r, g, b)
	--if self.liveSessionActive and self:GetCurrentPreset().uid == self.livePresetUID then
	--	self:LiveSession_QueueColorUpdate()
	--end
end

function MethodDungeonTools:UpdateAutomaticColors(index)
	if not db.colorPaletteInfo.autoColoring then return end
	for i = index or 1, self:GetPullsNum() do
		self:SetAutomaticColor(i)
	end
end

---ClearPull
---Clears all the npcs out of a pull
function MethodDungeonTools:ClearPull(index)
	table.wipe(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value.pulls[index])
    MethodDungeonTools:EnsureDBTables()
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index)
    MethodDungeonTools:ColorPull()
	--MethodDungeonTools:SetAutomaticColor(index)
end

---MovePullUp
---Moves the selected pull up
function MethodDungeonTools:MovePullUp(index)
	MethodDungeonTools:PresetsSwapPulls(index,index-1)
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index-1)
    MethodDungeonTools:ColorAllPulls(_, index-1)
	--MethodDungeonTools:UpdateAutomaticColors(index - 1)
end

---MovePullDown
---Moves the selected pull down
function MethodDungeonTools:MovePullDown(index)
	MethodDungeonTools:PresetsSwapPulls(index,index+1)
	MethodDungeonTools:ReloadPullButtons()
	MethodDungeonTools:SetSelectionToPull(index+1)
    MethodDungeonTools:ColorAllPulls(_, index)
	--MethodDungeonTools:UpdateAutomaticColors(index)
end

---DeletePull
---Deletes the selected pull and makes sure that a pull will be selected afterwards
function MethodDungeonTools:DeletePull(index)
    local pulls = self:GetPulls()
    if #pulls == 1 then return end
	self:PresetsDeletePull(index)
	self:ReloadPullButtons()
	local pullCount = 0
	for k,v in pairs(pulls) do
		pullCount = pullCount + 1
	end
	if index>pullCount then index = pullCount end
	self:SetSelectionToPull(index)
    --self:UpdateAutomaticColors(index)
    self:ColorAllPulls(_, index-1)
end

---RenamePreset
function MethodDungeonTools:RenamePreset(renameText)
	db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].text = renameText
	MethodDungeonTools.main_frame.RenameFrame:Hide()
	MethodDungeonTools:UpdatePresetDropDown()
end

---GetFirstNotSelectedPullButton
function MethodDungeonTools:GetFirstNotSelectedPullButton(start, direction)
    if not direction then
        direction = -1
    elseif direction == "UP" then
        direction = -1
    elseif direction == "DOWN" then
        direction = 1
    end

    local pullIdx = start
    while MethodDungeonTools.U.contains(MethodDungeonTools:GetCurrentPreset().value.selection, pullIdx)
            and MethodDungeonTools.U.isInRange(pullIdx, 1, #MethodDungeonTools:GetCurrentPreset().value.pulls) do
       pullIdx = pullIdx + direction
    end

    if not MethodDungeonTools.U.isInRange(pullIdx, 1, #MethodDungeonTools:GetCurrentPreset().value.pulls) then
        return
    end

    return pullIdx
end

function MethodDungeonTools:MakeRenameFrame(frame)
	frame.RenameFrame = AceGUI:Create("Frame")
	frame.RenameFrame:SetTitle(L"Rename Preset")
	frame.RenameFrame:SetWidth(350)
	frame.RenameFrame:SetHeight(150)
	frame.RenameFrame:EnableResize(false)
	frame.RenameFrame:SetLayout("Flow")
	frame.RenameFrame:SetCallback("OnClose", function(widget)

	end)
	frame.RenameFrame:Hide()

	local renameText
	frame.RenameFrame.Editbox = AceGUI:Create("EditBox")
	frame.RenameFrame.Editbox:SetLabel(L"Insert new Preset Name:")
	frame.RenameFrame.Editbox:SetWidth(200)
	frame.RenameFrame.Editbox:SetCallback("OnEnterPressed", function(...)
        local widget, event, text = ...
		--check if name is valid, block button if so, unblock if valid
		if MethodDungeonTools:SanitizePresetName(text) then
			frame.RenameFrame.PresetRenameLabel:SetText(nil)
			frame.RenameFrame.RenameButton:SetDisabled(false)
			frame.RenameFrame.RenameButton.text:SetTextColor(1,0.8196,0)
			renameText = text
		else
			frame.RenameFrame.PresetRenameLabel:SetText(L"Cannot rename preset to '"..text.."'")
			frame.RenameFrame.RenameButton:SetDisabled(true)
			frame.RenameFrame.RenameButton.text:SetTextColor(0.5,0.5,0.5)
			renameText = nil
		end
		frame.presetCreationFrame:DoLayout()
	end)

	frame.RenameFrame:AddChild(frame.RenameFrame.Editbox)

	frame.RenameFrame.RenameButton = AceGUI:Create("Button")
	frame.RenameFrame.RenameButton:SetText(L"Rename")
	frame.RenameFrame.RenameButton:SetWidth(100)
	frame.RenameFrame.RenameButton:SetCallback("OnClick",function() MethodDungeonTools:RenamePreset(renameText) end)
	frame.RenameFrame:AddChild(frame.RenameFrame.RenameButton)

	frame.RenameFrame.PresetRenameLabel = AceGUI:Create("Label")
	frame.RenameFrame.PresetRenameLabel:SetText(nil)
	frame.RenameFrame.PresetRenameLabel:SetWidth(390)
	frame.RenameFrame.PresetRenameLabel:SetColor(1,0,0)
	frame.RenameFrame:AddChild(frame.RenameFrame.PresetRenameLabel)

end


---MakeExportFrame
---Creates the frame used to export presets to a string which can be uploaded to text sharing websites like pastebin
function MethodDungeonTools:MakeExportFrame(frame)
	frame.ExportFrame = AceGUI:Create("Frame")
	frame.ExportFrame:SetTitle(L"Preset Export")
	frame.ExportFrame:SetWidth(600)
	frame.ExportFrame:SetHeight(400)
	frame.ExportFrame:EnableResize(false)
	frame.ExportFrame:SetLayout("Flow")
	frame.ExportFrame:SetCallback("OnClose", function(widget)

	end)

	frame.ExportFrameEditbox = AceGUI:Create("MultiLineEditBox")
	frame.ExportFrameEditbox:SetLabel(L"Preset Export:")
	frame.ExportFrameEditbox:SetWidth(600)
	frame.ExportFrameEditbox:DisableButton(true)
	frame.ExportFrameEditbox:SetNumLines(20)
	frame.ExportFrameEditbox:SetCallback("OnEnterPressed", function(widget, event, text)

	end)
	frame.ExportFrame:AddChild(frame.ExportFrameEditbox)
	--frame.presetCreationFrame:SetStatusText("AceGUI-3.0 Example Container Frame")
	frame.ExportFrame:Hide()
end


---MakeDeleteConfirmationFrame
---Creates the delete confirmation dialog that pops up when a user wants to delete a preset
function MethodDungeonTools:MakeDeleteConfirmationFrame(frame)
	frame.DeleteConfirmationFrame = AceGUI:Create("Frame")
	frame.DeleteConfirmationFrame:SetTitle(L"Delete Preset")
	frame.DeleteConfirmationFrame:SetWidth(250)
	frame.DeleteConfirmationFrame:SetHeight(120)
	frame.DeleteConfirmationFrame:EnableResize(false)
	frame.DeleteConfirmationFrame:SetLayout("Flow")
	frame.DeleteConfirmationFrame:SetCallback("OnClose", function(widget)

	end)

	frame.DeleteConfirmationFrame.label = AceGUI:Create("Label")
	frame.DeleteConfirmationFrame.label:SetWidth(390)
	frame.DeleteConfirmationFrame.label:SetHeight(10)
	--frame.DeleteConfirmationFrame.label:SetColor(1,0,0)
	frame.DeleteConfirmationFrame:AddChild(frame.DeleteConfirmationFrame.label)

	frame.DeleteConfirmationFrame.OkayButton = AceGUI:Create("Button")
	frame.DeleteConfirmationFrame.OkayButton:SetText(L"Delete")
	frame.DeleteConfirmationFrame.OkayButton:SetWidth(100)
	frame.DeleteConfirmationFrame.OkayButton:SetCallback("OnClick",function()
		MethodDungeonTools:DeletePreset(db.currentPreset[db.currentDungeonIdx])
		frame.DeleteConfirmationFrame:Hide()
	end)
	frame.DeleteConfirmationFrame.CancelButton = AceGUI:Create("Button")
	frame.DeleteConfirmationFrame.CancelButton:SetText(L"Cancel")
	frame.DeleteConfirmationFrame.CancelButton:SetWidth(100)
	frame.DeleteConfirmationFrame.CancelButton:SetCallback("OnClick",function()
		frame.DeleteConfirmationFrame:Hide()
	end)

	frame.DeleteConfirmationFrame:AddChild(frame.DeleteConfirmationFrame.OkayButton)
	frame.DeleteConfirmationFrame:AddChild(frame.DeleteConfirmationFrame.CancelButton)
	frame.DeleteConfirmationFrame:Hide()

end


---MakeClearConfirmationFrame
---Creates the clear confirmation dialog that pops up when a user wants to clear a preset
function MethodDungeonTools:MakeClearConfirmationFrame(frame)
	frame.ClearConfirmationFrame = AceGUI:Create("Frame")
	frame.ClearConfirmationFrame:SetTitle(L"Reset Preset")
	frame.ClearConfirmationFrame:SetWidth(250)
	frame.ClearConfirmationFrame:SetHeight(120)
	frame.ClearConfirmationFrame:EnableResize(false)
	frame.ClearConfirmationFrame:SetLayout("Flow")
	frame.ClearConfirmationFrame:SetCallback("OnClose", function(widget)

	end)

	frame.ClearConfirmationFrame.label = AceGUI:Create("Label")
	frame.ClearConfirmationFrame.label:SetWidth(390)
	frame.ClearConfirmationFrame.label:SetHeight(10)
	--frame.DeleteConfirmationFrame.label:SetColor(1,0,0)
	frame.ClearConfirmationFrame:AddChild(frame.ClearConfirmationFrame.label)

	frame.ClearConfirmationFrame.OkayButton = AceGUI:Create("Button")
	frame.ClearConfirmationFrame.OkayButton:SetText(L"Clear")
	frame.ClearConfirmationFrame.OkayButton:SetWidth(100)
	frame.ClearConfirmationFrame.OkayButton:SetCallback("OnClick",function()
		self:ClearPreset(self:GetCurrentPreset())
        if self.liveSessionActive and self:GetCurrentPreset().uid == self.livePresetUID then MethodDungeonTools:LiveSession_SendCommand("clear") end
		frame.ClearConfirmationFrame:Hide()
	end)
	frame.ClearConfirmationFrame.CancelButton = AceGUI:Create("Button")
	frame.ClearConfirmationFrame.CancelButton:SetText(L"Cancel")
	frame.ClearConfirmationFrame.CancelButton:SetWidth(100)
	frame.ClearConfirmationFrame.CancelButton:SetCallback("OnClick",function()
		frame.ClearConfirmationFrame:Hide()
	end)

	frame.ClearConfirmationFrame:AddChild(frame.ClearConfirmationFrame.OkayButton)
	frame.ClearConfirmationFrame:AddChild(frame.ClearConfirmationFrame.CancelButton)
	frame.ClearConfirmationFrame:Hide()

end

---OpenConfirmationFrame
---Creates a generic dialog that pops up when a user wants needs confirmation for an action
function MethodDungeonTools:OpenConfirmationFrame(width,height,title,buttonText,prompt,callback,buttonText2,callback2)
    local f = MethodDungeonTools.main_frame.ConfirmationFrame
    if not f then
        MethodDungeonTools.main_frame.ConfirmationFrame = AceGUI:Create("Frame")
        f = MethodDungeonTools.main_frame.ConfirmationFrame
        f:EnableResize(false)
        f:SetLayout("Flow")
        f:SetCallback("OnClose", function(widget) end)

        f.label = AceGUI:Create("Label")
        f.label:SetWidth(390)
        f.label:SetHeight(height-20)
        f:AddChild(f.label)

        f.OkayButton = AceGUI:Create("Button")
        f.OkayButton:SetWidth(100)
        f:AddChild(f.OkayButton)

        f.CancelButton = AceGUI:Create("Button")
        f.CancelButton:SetText("Cancel")
        f.CancelButton:SetWidth(100)
        f.CancelButton:SetCallback("OnClick",function()
            MethodDungeonTools:HideAllDialogs()
        end)
        f:AddChild(f.CancelButton)
    end
    f:SetWidth(width or 250)
    f:SetHeight(height or 120)
    f:SetTitle(title)
    f.OkayButton:SetText(buttonText)
    f.OkayButton:SetCallback("OnClick",function()callback()MethodDungeonTools:HideAllDialogs() end)
    if buttonText2 then
        f.CancelButton:SetText(buttonText2) else
        f.CancelButton:SetText("Cancel")
    end
    if callback2 then
        f.CancelButton:SetCallback("OnClick",function()callback2()MethodDungeonTools:HideAllDialogs() end)
    else
        f.CancelButton:SetCallback("OnClick",function()MethodDungeonTools:HideAllDialogs() end)
    end
    MethodDungeonTools:HideAllDialogs()
    f:ClearAllPoints()
    f:SetPoint("CENTER",MethodDungeonTools.main_frame,"CENTER",0,50)
    f.label:SetText(prompt)
    f:Show()
end

---CreateTutorialButton
---Creates the tutorial button and sets up the help plate frames
function MethodDungeonTools:CreateTutorialButton(parent)
    local scale = self:GetScale()
    local sidePanelHeight = MethodDungeonTools.main_frame.sidePanel.PullButtonScrollGroup.frame:GetHeight()
    local helpPlate = {
        FramePos = { x = 0,	y = 0 },
        FrameSize = { width = sizex, height = sizey	},
        [1] = { ButtonPos = { x = 205,	y = 0 }, HighLightBox = { x = 0, y = 0, width = 200, height = 56 },		ToolTipDir = "RIGHT",		ToolTipText = "Select a dungeon and navigate to different sublevels" },
        [2] = { ButtonPos = { x = 205,	y = -210*scale }, HighLightBox = { x = 0, y = -58, width = (sizex-6)*scale, height = (sizey*scale)-58 },	ToolTipDir = "RIGHT",	ToolTipText = "Click to select enemies\nCTRL-Click to single-select enemies\nSHIFT-Click to select enemies and create a new pull" },
        [3] = { ButtonPos = { x = 900*scale,	y = 0*scale }, HighLightBox = { x = 838*scale, y = 30, width = 251, height = 115 },	ToolTipDir = "LEFT",	ToolTipText = "Manage, share and collaborate on presets" },
        [4] = { ButtonPos = { x = 900*scale,	y = -87*scale }, HighLightBox = { x = 838*scale, y = 30-115, width = 251, height = 102 },	ToolTipDir = "LEFT",	ToolTipText = "Customize dungeon options" },
        [5] = { ButtonPos = { x = 900*scale,	y = -(115+102*scale) }, HighLightBox = { x = 838*scale, y = (30-(115+102)), width = 251, height = (sidePanelHeight)+43 },	ToolTipDir = "LEFT",	ToolTipText = "Create and manage your pulls\nRight click for more options" },
    }
    if not parent.HelpButton then
        parent.HelpButton = CreateFrame("Button","MDTMainHelpPlateButton",parent,"MainHelpPlateButton")
        parent.HelpButton:ClearAllPoints()
        parent.HelpButton:SetPoint("TOPLEFT",parent,"TOPLEFT",0,48)
        parent.HelpButton:SetScale(0.8)
        parent.HelpButton:SetFrameStrata(mainFrameStrata)
        parent.HelpButton:SetFrameLevel(6)
        parent.HelpButton:Hide()
        --hook to make button hide
        local originalHide = parent.Hide
        function parent:Hide(...)
            parent.HelpButton:Hide()
            return originalHide(self, ...)
        end
        local function TutorialButtonOnHide(self)
            HelpPlate_Hide(true)
        end
        parent.HelpButton:SetScript("OnHide",TutorialButtonOnHide)
    end
    local function TutorialButtonOnClick(self)
        if not HelpPlate_IsShowing(helpPlate) then
            HelpPlate_Show(helpPlate, MethodDungeonTools.main_frame, self)
        else
            HelpPlate_Hide(true)
        end
    end
    parent.HelpButton:SetScript("OnClick",TutorialButtonOnClick)
end

---RegisterOptions
---Register the options of the addon to the blizzard options
function MethodDungeonTools:RegisterOptions()
    MethodDungeonTools.blizzardOptionsMenuTable = {
        name = "Method Dungeon Tools",
        type = 'group',
        args = {
            enable = {
                type = 'toggle',
                name = "Enable Minimap Button",
                desc = "If the Minimap Button is enabled",
                get = function() return not db.minimap.hide end,
                set = function(_, newValue)
                    db.minimap.hide = not newValue
                    if not db.minimap.hide then
                        icon:Show("MethodDungeonTools")
                    else
                        icon:Hide("MethodDungeonTools")
                    end
                end,
                order = 1,
                width = "full",
            },
            tooltipSelect ={
                type = 'select',
                name = "Choose NPC tooltip position",
                values = {
                    [1] = "Next to the NPC",
                    [2] = "In the bottom right corner",
                },
                get = function() return db.tooltipInCorner and 2 or 1 end,
                set = function(_,newValue)
                    if newValue == 1 then db.tooltipInCorner = false end
                    if newValue == 2 then db.tooltipInCorner = true end
                end,
                style = 'dropdown',
            },
            enemyForcesFormat = {
                type = "select",
                name = "Choose Enemy Forces Format",
                values = {
                    [1] = "Forces only: 5/200",
                    [2] = "Forces+%: 5/200 (2.5%)",
                },
                get = function() return db.enemyForcesFormat end,
                set = function(_,newValue) db.enemyForcesFormat = newValue end,
                style = "dropdown",
            },
            enemyStyle = {
                type = "select",
                name = "Choose Enemy Style. Requires Reload",
                values = {
                    [1] = "Portrait",
                    [2] = "Plain Texture",
                },
                get = function() return db.enemyStyle end,
                set = function(_,newValue) db.enemyStyle = newValue end,
                style = "dropdown",
            },

        }
    }
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("MethodDungeonTools", MethodDungeonTools.blizzardOptionsMenuTable)
	self.blizzardOptionsMenu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MethodDungeonTools", "MethodDungeonTools")
end

---Round
function MethodDungeonTools:Round(number, decimals)
	return (("%%.%df"):format(decimals)):format(number)
end

---RGBToHex
function MethodDungeonTools:RGBToHex(r,g,b)
	r = r*255
	g = g*255
	b = b*255
	return ("%.2x%.2x%.2x"):format(r, g, b)
end
---HexToRGB
function MethodDungeonTools:HexToRGB(rgb)
	if string.len(rgb) == 6 then
		local r, g, b
		r, g, b = tonumber('0x'..strsub(rgb, 0, 2)), tonumber('0x'..strsub(rgb, 3, 4)), tonumber('0x'..strsub(rgb, 5, 6))
		if not r then r = 0 else r = r/255 end
		if not g then g = 0 else g = g/255 end
		if not b then b = 0 else b = b/255 end
		return r,g,b
	else
		return
	end
end
---HSVToRGB
---https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB_alternative
function MethodDungeonTools:HSVtoRGB(H, S, V)
	H = H % 361

	local function f(n)
		k = (n + H/60) % 6
		return V - V * S * math.max(math.min(k, 4 - k, 1), 0)
	end

	return f(5), f(3), f(1)
end

---DeepCopy
function MethodDungeonTools:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[MethodDungeonTools:DeepCopy(orig_key)] = MethodDungeonTools:DeepCopy(orig_value)
        end
        setmetatable(copy, MethodDungeonTools:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---StorePresetObject
---scale if preset comes from live session
function MethodDungeonTools:StorePresetObject(obj,ignoreScale,preset)
    --adjust scale
    if not ignoreScale then
        local scale = self:GetScale()
        if obj.n then
            obj.d[1] = obj.d[1]*(1/scale)
            obj.d[2] = obj.d[2]*(1/scale)
        else
            for idx,coord in pairs(obj.l) do
                obj.l[idx] = self:Round(obj.l[idx]*(1/scale),1)
            end
        end
    end
	preset = preset or self:GetCurrentPreset()
    preset.objects = preset.objects or {}
	--we insert the object infront of the first hidden oject
	local pos = 1
	for k,v in ipairs(preset.objects) do
		pos = pos + 1
		if v.d[4]==false then
			pos = pos - 1
		end
	end
	if pos>1 then
		tinsert(preset.objects,pos,self:DeepCopy(obj))
	else
		tinsert(preset.objects,self:DeepCopy(obj))
	end
end

---UpdatePresetObjectOffsets
---excluding notes, these are handled in OverrideScrollFrameScripts
function MethodDungeonTools:UpdatePresetObjectOffsets(idx,x,y,preset,silent)
    --adjust coords to scale
    local scale = self:GetScale()
    x = self:Round(x*(1/scale),1)
    y = self:Round(y*(1/scale),1)
	preset = preset or self:GetCurrentPreset()
	for objectIndex,obj in pairs(preset.objects) do
		if objectIndex == idx then
			for coordIdx,coord in pairs(obj.l) do
				if coordIdx%2==1 then
					obj.l[coordIdx] = coord-x
				else
					obj.l[coordIdx] = coord-y
				end
			end
		end
	end
    --redraw everything
	if not silent then self:DrawAllPresetObjects() end
end


---DrawAllPresetObjects
---Draws all Preset objects on the map canvas/sublevel
function MethodDungeonTools:DrawAllPresetObjects()
    self:ReleaseAllActiveTextures()
    local scale = self:GetScale()
    local currentPreset = self:GetCurrentPreset()
    local currentSublevel = self:GetCurrentSubLevel()
    currentPreset.objects = currentPreset.objects or {}
    for objectIndex,obj in pairs(currentPreset.objects) do
        self:DrawPresetObject(obj,objectIndex,scale,currentPreset,currentSublevel)
    end
end

---DrawPresetObject
---Draws specific preset object
function MethodDungeonTools:DrawPresetObject(obj,objectIndex,scale,currentPreset,currentSublevel)
    if not objectIndex then
        for oIndex,o in pairs(currentPreset.objects) do
            if o == obj then
                objectIndex = oIndex
                break
            end
        end
    end
    --d: size,lineFactor,sublevel,shown,colorstring,drawLayer,[smooth]
    --l: x1,y1,x2,y2,...
    local color = {}
    if obj.d[3] == currentSublevel and obj.d[4] then
        if obj.n then
            local x = obj.d[1]*scale
            local y = obj.d[2]*scale
            local text = obj.d[5]
            self:DrawNote(x,y,text,objectIndex)
        else
            obj.d[1] = obj.d[1] or 5
            color.r,color.g,color.b = self:HexToRGB(obj.d[5])
            --lines
            local x1,y1,x2,y2
            local lastx,lasty
            for _,coord in pairs(obj.l) do
                if not x1 then x1 = coord
                elseif not y1 then y1 = coord
                elseif not x2 then
                    x2 = coord
                    lastx = coord
                elseif not y2 then
                    y2 = coord
                    lasty = coord
                end
                if x1 and y1 and x2 and y2 then
                    x1 = x1*scale
                    x2 = x2*scale
                    y1 = y1*scale
                    y2 = y2*scale
                    self:DrawLine(x1,y1,x2,y2,obj.d[1]*0.3*scale,color,obj.d[7],nil,obj.d[6],obj.d[2],nil,objectIndex)
                    --circles if smooth
                    if obj.d[7] then
                        self:DrawCircle(x1,y1,obj.d[1]*0.3*scale,color,nil,obj.d[6],nil,objectIndex)
                        self:DrawCircle(x2,y2,obj.d[1]*0.3*scale,color,nil,obj.d[6],nil,objectIndex)

                    end
                    x1,y1,x2,y2 = nil,nil,nil,nil
                end
            end
            --triangle
            if obj.t and lastx and lasty then
                lastx = lastx*scale
                lasty = lasty*scale
                self:DrawTriangle(lastx,lasty,obj.t[1],obj.d[1]*scale,color,nil,obj.d[6],nil,objectIndex)
            end
            --remove empty objects leftover from erasing
            if obj.l then
                local lineCount = 0
                for _,_ in pairs(obj.l) do
                    lineCount = lineCount +1
                end
                if lineCount == 0 then
                    currentPreset.objects[objectIndex] = nil
                end
            end
        end
    end
end

---DeletePresetObjects
---Deletes objects from the current preset in the current sublevel
function MethodDungeonTools:DeletePresetObjects(preset, silent)
	preset = preset or self:GetCurrentPreset()
    if preset == self:GetCurrentPreset() then silent = false end
    local currentSublevel = self:GetCurrentSubLevel()
    for objectIndex,obj in pairs(preset.objects) do
        if obj.d[3] == currentSublevel then
            preset.objects[objectIndex] = nil
        end
    end
    if not silent then self:DrawAllPresetObjects() end
end

---StepBack
---Undo the latest drawing
function MethodDungeonTools:PresetObjectStepBack(preset,silent)
    preset = preset or self:GetCurrentPreset()
    if preset == self:GetCurrentPreset() then silent = false end
    preset.objects = preset.objects or {}
    local length = 0
    for k,v in pairs(preset.objects) do
        length = length + 1
    end
    if length>0 then
        for i = length,1,-1 do
            if preset.objects[i] and preset.objects[i].d[4] then
                preset.objects[i].d[4] = false
                if not silent then self:DrawAllPresetObjects() end
                break
            end
        end
    end
end

---StepForward
---Redo the latest drawing
function MethodDungeonTools:PresetObjectStepForward(preset,silent)
    preset = preset or MethodDungeonTools:GetCurrentPreset()
    if preset == self:GetCurrentPreset() then silent = false end
    preset.objects = preset.objects or {}
    local length = 0
    for k,v in ipairs(preset.objects) do
        length = length + 1
    end
    if length>0 then
        for i = 1,length do
            if preset.objects[i] and not preset.objects[i].d[4] then
                preset.objects[i].d[4] = true
                if not silent then self:DrawAllPresetObjects() end
                break
            end
        end
    end
end

function MethodDungeonTools:FixAceGUIShowHide(widget,frame,isFrame,hideOnly)
    frame = frame or MethodDungeonTools.main_frame
    local originalShow,originalHide = frame.Show,frame.Hide
    if not isFrame then
        widget = widget.frame
    end
    function frame:Hide(...)
        widget:Hide()
        return originalHide(self, ...)
    end
    if hideOnly then return end
    function frame:Show(...)
        widget:Show()
        return originalShow(self, ...)
    end
end

function MethodDungeonTools:GetCurrentAffixWeek()
    if not IsAddOnLoaded("Blizzard_ChallengesUI") then
        LoadAddOn("Blizzard_ChallengesUI")
    end
    C_MythicPlus.RequestCurrentAffixes()
    C_MythicPlus.RequestMapInfo()
    C_MythicPlus.RequestRewards()
    local affixIds = C_MythicPlus.GetCurrentAffixes() --table
    if not affixIds then return end
    for week,affixes in ipairs(affixWeeks) do
        if affixes[1] == affixIds[2].id and affixes[2] == affixIds[3].id and affixes[3] == affixIds[1].id then
            return week
        end
    end
    return 1
end

---PrintCurrentAffixes
---Helper function to print out current affixes with their ids and their names
function MethodDungeonTools:PrintCurrentAffixes()
    --run this once so blizz stuff is loaded
    MethodDungeonTools:GetCurrentAffixWeek()
    --https://www.wowhead.com/affixes
    local affixNames = {
        [1] ="Overflowing",
        [2] ="Skittish",
        [3] ="Volcanic",
        [4] ="Necrotic",
        [5] ="Teeming",
        [6] ="Raging",
        [7] ="Bolstering",
        [8] ="Sanguine",
        [9] ="Tyrannical",
        [10] ="Fortified",
        [11] ="Bursting",
        [12] ="Grievous",
        [13] ="Explosive",
        [14] ="Quaking",
        [15] ="Relentless",
        [16] ="Infested",
        [117] ="Reaping",
        [119] ="Beguiling",
        [120] ="Awakened",
    }
    local affixIds = C_MythicPlus.GetCurrentAffixes()
    for idx,data in ipairs(affixIds) do
        print(data.id,affixNames[data.id])
    end
end

---IsPlayerInGroup
---Checks if the players is in a group/raid and returns the type
function MethodDungeonTools:IsPlayerInGroup()
    local inGroup = (UnitInRaid("player") and "RAID") or (IsInGroup() and "PARTY")
    return inGroup
end

function MethodDungeonTools:ResetMainFramePos(soft)
    --soft reset just redraws the window with existing coordinates from db
    local f = self.main_frame
    if not soft then
        db.nonFullscreenScale = 1
        db.maximized = false
        if not framesInitialized then initFrames() end
        f.maximizeButton:Minimize()
        db.xoffset = 0
        db.yoffset = -150
        db.anchorFrom = "TOP"
        db.anchorTo = "TOP"
    end
    f:ClearAllPoints()
    f:SetPoint(db.anchorTo, UIParent,db.anchorFrom, db.xoffset, db.yoffset)
end

function MethodDungeonTools:DropIndicator()
    local indicator = MethodDungeonTools.main_frame.drop_indicator
    if not indicator then
        indicator = CreateFrame("Frame", "MethodDungeonTools_DropIndicator")
        indicator:SetHeight(4)
        indicator:SetFrameStrata("FULLSCREEN")

        local texture = indicator:CreateTexture(nil, "FULLSCREEN")
        texture:SetBlendMode("ADD")
        texture:SetAllPoints(indicator)
        texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")

        local icon = indicator:CreateTexture(nil, "OVERLAY")
        icon:ClearAllPoints()
        icon:SetSize(16, 16)
        icon:SetPoint("CENTER", indicator)

        indicator.icon = icon
        indicator.texture = texture
        MethodDungeonTools.main_frame.drop_indicator = indicator

        indicator:Hide()
    end

    return indicator
end

function MethodDungeonTools:IsShown_DropIndicator()
    local indicator = MethodDungeonTools:DropIndicator()
    return indicator:IsShown()
end

function MethodDungeonTools:Show_DropIndicator(target, pos)
    local indicator = MethodDungeonTools:DropIndicator()
    indicator:ClearAllPoints()
    if pos == "TOP" then
        indicator:SetPoint("BOTTOMLEFT", target.frame, "TOPLEFT", 0, -1)
        indicator:SetPoint("BOTTOMRIGHT", target.frame, "TOPRIGHT", 0, -1)
        indicator:Show()
    elseif pos == "BOTTOM" then
        indicator:SetPoint("TOPLEFT", target.frame, "BOTTOMLEFT", 0, 1)
        indicator:SetPoint("TOPRIGHT", target.frame, "BOTTOMRIGHT", 0, 1)
        indicator:Show()
    end
end

function MethodDungeonTools:Hide_DropIndicator()
    local indicator = MethodDungeonTools:DropIndicator()
    indicator:Hide()
end

function MethodDungeonTools:GetSelection()
    if not MethodDungeonTools:GetCurrentPreset().value.selection or #MethodDungeonTools:GetCurrentPreset().value.selection == 0 then
        MethodDungeonTools:GetCurrentPreset().value.selection = { MethodDungeonTools:GetCurrentPreset().value.currentPull }
    end

    return MethodDungeonTools:GetCurrentPreset().value.selection
end

function MethodDungeonTools:GetScrollingAmount(scrollFrame, pixelPerSecond)
    local viewheight = scrollFrame.frame.obj.content:GetHeight()
    return (pixelPerSecond / viewheight) * 1000
end

function MethodDungeonTools:ScrollToPull(pullIdx)
    -- Get scroll frame
    local scrollFrame = MethodDungeonTools.main_frame.sidePanel.pullButtonsScrollFrame
    -- Get amount of total pulls plus the extra button "+ Add Pull"
    local pulls = #MethodDungeonTools:GetCurrentPreset().value.pulls + 1 or 1
    local percentage = pullIdx / pulls
    local value = percentage * 1000
    scrollFrame:SetScroll(value)
    scrollFrame:FixScroll()
end

function MethodDungeonTools:CopyPullOptions(sourceIdx, destinationIdx)
    local preset = MethodDungeonTools:GetCurrentPreset()
    local pulls = preset.value.pulls
    local source = pulls[sourceIdx]
    local destination = pulls[destinationIdx]

    if source and destination then
        for optionName, optionValue in pairs(source) do
            -- Assure, that it is an option and not an enemy index
            if not string.match(optionName, "^%d+$") then
                destination[optionName] = optionValue
            end
        end
    end
end

function MethodDungeonTools:GetPullButton(pullIdx)
    local frame = MethodDungeonTools.main_frame.sidePanel
    return frame.newPullButtons[pullIdx]
end

function MethodDungeonTools:UpdatePullButtonColor(pullIdx, r, g, b)
    local button = MethodDungeonTools:GetPullButton(pullIdx)

    local function updateSwatch(t)
        for k,v in pairs(t) do
            if v.hasColorSwatch then
                v.r,v.g,v.b = r,g,b
                return
            end
        end
    end

    button.color.r, button.color.g, button.color.b = r, g, b
    updateSwatch(button.menu)
    updateSwatch(button.multiselectMenu)
    button:UpdateColor()
end

--/run MethodDungeonTools:ResetDataCache();
function MethodDungeonTools:ResetDataCache()
    db.dungeonEnemies = nil
    db.mapPOIs = nil
end

function initFrames()
    local main_frame = CreateFrame("frame", "MethodDungeonToolsFrame", UIParent)
    tinsert(UISpecialFrames,"MethodDungeonToolsFrame")

    --cache dungeon data to not lose data during reloads
    if db.devMode then
        if db.dungeonEnemies then
            MethodDungeonTools.dungeonEnemies = db.dungeonEnemies
        else
            db.dungeonEnemies = MethodDungeonTools.dungeonEnemies
        end
        if db.mapPOIs then
            MethodDungeonTools.mapPOIs = db.mapPOIs
        else
            db.mapPOIs = MethodDungeonTools.mapPOIs
        end
    end

    db.nonFullscreenScale = db.nonFullscreenScale or 1
    if not db.maximized then db.scale = db.nonFullscreenScale end
	main_frame:SetFrameStrata(mainFrameStrata)
	main_frame:SetFrameLevel(1)
	main_frame.background = main_frame:CreateTexture(nil, "BACKGROUND")
	main_frame.background:SetAllPoints()
	main_frame.background:SetDrawLayer(canvasDrawLayer, 1)
	main_frame.background:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))
	main_frame.background:SetAlpha(0.2)
	main_frame:SetSize(sizex*db.scale, sizey*db.scale)
	main_frame:SetResizable(true)
    main_frame:SetMinResize(sizex*0.75,sizey*0.75)
    local _,_,fullscreenScale = MethodDungeonTools:GetFullScreenSizes()
    main_frame:SetMaxResize(sizex*fullscreenScale,sizey*fullscreenScale)
	MethodDungeonTools.main_frame = main_frame

    main_frame.mainFrametex = main_frame:CreateTexture(nil, "BACKGROUND")
    main_frame.mainFrametex:SetAllPoints()
    main_frame.mainFrametex:SetDrawLayer(canvasDrawLayer, -5)
    main_frame.mainFrametex:SetColorTexture(unpack(MethodDungeonTools.BackdropColor))

    local version = GetAddOnMetadata(AddonName, "Version"):gsub("%.","")
    db.version = tonumber(version)
	-- Set frame position
	main_frame:ClearAllPoints()
	main_frame:SetPoint(db.anchorTo, UIParent,db.anchorFrom, db.xoffset, db.yoffset)
    main_frame.contextDropdown = L_Create_UIDropDownMenu("MethodDungeonToolsContextDropDown", nil)

    MethodDungeonTools:CheckCurrentZone(true)
    MethodDungeonTools:EnsureDBTables()
	MethodDungeonTools:MakeTopBottomTextures(main_frame)
	MethodDungeonTools:MakeMapTexture(main_frame)
	MethodDungeonTools:MakeSidePanel(main_frame)
    MethodDungeonTools:CreateMenu()
	MethodDungeonTools:MakePresetCreationFrame(main_frame)
	MethodDungeonTools:MakePresetImportFrame(main_frame)
    MethodDungeonTools:DungeonEnemies_CreateFramePools()
	--MethodDungeonTools:UpdateDungeonEnemies(main_frame)
	MethodDungeonTools:CreateDungeonSelectDropdown(main_frame)
	MethodDungeonTools:MakePullSelectionButtons(main_frame.sidePanel)
	MethodDungeonTools:MakeExportFrame(main_frame)
	MethodDungeonTools:MakeRenameFrame(main_frame)
	MethodDungeonTools:MakeDeleteConfirmationFrame(main_frame)
	MethodDungeonTools:MakeClearConfirmationFrame(main_frame)
	MethodDungeonTools:CreateTutorialButton(main_frame)
    MethodDungeonTools:POI_CreateFramePools()
    MethodDungeonTools:MakeChatPresetImportFrame(main_frame)
	MethodDungeonTools:MakeSendingStatusBar(main_frame)
	MethodDungeonTools:MakeAutomaticColorsFrame(main_frame)
    MethodDungeonTools:MakeCustomColorFrame(main_frame.automaticColorsFrame)

    --devMode
    if db.devMode and MethodDungeonTools.CreateDevPanel then
        MethodDungeonTools:CreateDevPanel(MethodDungeonTools.main_frame)
    end

    --ElvUI skinning
    local skinTooltip = function(tooltip)
        if IsAddOnLoaded("ElvUI") and ElvUI[1].Tooltip then
            local borderTextures = {"BorderBottom","BorderBottomLeft","BorderBottomRight","BorderLeft","BorderRight","BorderTop","BorderTopLeft","BorderTopRight"}
            for k,v in pairs(borderTextures) do
                tooltip[v]:Kill()
            end
            tooltip.Background:Kill()
            tooltip:HookScript("OnShow",function(self)
                if self:IsForbidden() then return end
                self:SetTemplate("Transparent", nil, true) --ignore updates
                local r, g, b = self:GetBackdropColor()
                self:SetBackdropColor(r, g, b, ElvUI[1].Tooltip.db.colorAlpha)
            end)
            if tooltip.String then tooltip.String:SetFont(tooltip.String:GetFont(),11) end
            if tooltip.topString then tooltip.topString:SetFont(tooltip.topString:GetFont(),11) end
            if tooltip.botString then tooltip.botString:SetFont(tooltip.botString:GetFont(),11) end
        end
    end
    --tooltip new
    do
        MethodDungeonTools.tooltip = CreateFrame("Frame", "MethodDungeonToolsModelTooltip", UIParent, "TooltipBorderedFrameTemplate")
        local tooltip = MethodDungeonTools.tooltip
        tooltip:SetClampedToScreen(true)
        tooltip:SetFrameStrata("TOOLTIP")
        tooltip.mySizes ={x=290,y=120}
        tooltip:SetSize(tooltip.mySizes.x, tooltip.mySizes.y)
        tooltip.Model = CreateFrame("PlayerModel", nil, tooltip)
        tooltip.Model:SetFrameLevel(1)
        tooltip.Model:SetSize(100,100)
        tooltip.Model.fac = 0
        tooltip.Model:SetScript("OnUpdate",function (self,elapsed)
            self.fac = self.fac + 0.5
            if self.fac >= 360 then
                self.fac = 0
            end
            self:SetFacing(PI*2 / 360 * self.fac)
        end)
        tooltip.Model:SetPoint("TOPLEFT", tooltip, "TOPLEFT",7,-7)
        tooltip.String = tooltip:CreateFontString("MethodDungeonToolsToolTipString")
        tooltip.String:SetFontObject("GameFontNormalSmall")
        tooltip.String:SetFont(tooltip.String:GetFont(),10)
        tooltip.String:SetTextColor(1, 1, 1, 1)
        tooltip.String:SetJustifyH("LEFT")
        --tooltip.String:SetJustifyV("CENTER")
        tooltip.String:SetWidth(tooltip:GetWidth())
        tooltip.String:SetHeight(90)
        tooltip.String:SetWidth(175)
        tooltip.String:SetText(" ")
        tooltip.String:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 110, -10)
        tooltip.String:Show()
        skinTooltip(tooltip)
    end

	--pullTooltip
	do
		MethodDungeonTools.pullTooltip = CreateFrame("Frame", "MethodDungeonToolsPullTooltip", UIParent, "TooltipBorderedFrameTemplate")
        --MethodDungeonTools.pullTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        local pullTT = MethodDungeonTools.pullTooltip
        MethodDungeonTools.pullTooltip:SetClampedToScreen(true)
		MethodDungeonTools.pullTooltip:SetFrameStrata("TOOLTIP")
        MethodDungeonTools.pullTooltip.myHeight = 160
		MethodDungeonTools.pullTooltip:SetSize(250, MethodDungeonTools.pullTooltip.myHeight)
        MethodDungeonTools.pullTooltip.Model = CreateFrame("PlayerModel", nil, MethodDungeonTools.pullTooltip)
        MethodDungeonTools.pullTooltip.Model:SetFrameLevel(1)
        MethodDungeonTools.pullTooltip.Model.fac = 0
        if true then
            MethodDungeonTools.pullTooltip.Model:SetScript("OnUpdate",function (self,elapsed)
                self.fac = self.fac + 0.5
                if self.fac >= 360 then
                    self.fac = 0
                end
                self:SetFacing(PI*2 / 360 * self.fac)
            end)
        else
            MethodDungeonTools.pullTooltip.Model:SetPortraitZoom(1)
            MethodDungeonTools.pullTooltip.Model:SetFacing(PI*2 / 360 * 2)
        end

        MethodDungeonTools.pullTooltip.Model:SetSize(110,110)
        MethodDungeonTools.pullTooltip.Model:SetPoint("TOPLEFT", MethodDungeonTools.pullTooltip, "TOPLEFT",7,-7)

        MethodDungeonTools.pullTooltip.topString = MethodDungeonTools.pullTooltip:CreateFontString("MethodDungeonToolsToolTipString")
        MethodDungeonTools.pullTooltip.topString:SetFontObject("GameFontNormalSmall")
        MethodDungeonTools.pullTooltip.topString:SetFont(MethodDungeonTools.pullTooltip.topString:GetFont(),10)
        MethodDungeonTools.pullTooltip.topString:SetTextColor(1, 1, 1, 1)
        MethodDungeonTools.pullTooltip.topString:SetJustifyH("LEFT")
        MethodDungeonTools.pullTooltip.topString:SetJustifyV("TOP")
        MethodDungeonTools.pullTooltip.topString:SetHeight(110)
        MethodDungeonTools.pullTooltip.topString:SetWidth(130)
        MethodDungeonTools.pullTooltip.topString:SetPoint("TOPLEFT", MethodDungeonTools.pullTooltip, "TOPLEFT", 110, -7)
        MethodDungeonTools.pullTooltip.topString:Hide()

        local heading = MethodDungeonTools.pullTooltip:CreateTexture(nil, "TOOLTIP")
        heading:SetHeight(8)
        heading:SetPoint("LEFT", 12, -30)
        heading:SetPoint("RIGHT", MethodDungeonTools.pullTooltip, "RIGHT", -12, -30)
        heading:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        heading:SetTexCoord(0.81, 0.94, 0.5, 1)
        heading:Show()

        MethodDungeonTools.pullTooltip.botString = MethodDungeonTools.pullTooltip:CreateFontString("MethodDungeonToolsToolTipString")
        local botString = MethodDungeonTools.pullTooltip.botString
        botString:SetFontObject("GameFontNormalSmall")
        botString:SetFont(MethodDungeonTools.pullTooltip.topString:GetFont(),10)
        botString:SetTextColor(1, 1, 1, 1)
        botString:SetJustifyH("TOP")
        botString:SetJustifyV("TOP")
        botString:SetHeight(23)
        botString:SetWidth(250)
        botString.defaultText = L"Forces: %d\nTotal: %d/%d"
        botString:SetPoint("TOPLEFT", heading, "LEFT", -12, -7)
        botString:Hide()
        skinTooltip(pullTT)
	end

	MethodDungeonTools:initToolbar(main_frame)
    if db.toolbarExpanded then
        main_frame.toolbar.toggleButton:Click()
    end

    --ping
    MethodDungeonTools.ping = CreateFrame("PlayerModel", nil, MethodDungeonTools.main_frame.mapPanelFrame)
    local ping = MethodDungeonTools.ping
    --ping:SetModel("interface/minimap/ping/minimapping.m2")
    ping:SetModel(120590)
    ping:SetPortraitZoom(1)
    ping:SetCamera(1)
    ping:SetFrameLevel(50)
    ping:SetFrameStrata("DIALOG")
    ping.mySize = 45
    ping:SetSize(ping.mySize,ping.mySize)
    ping:Hide()

    --Set affix dropdown to preset week
    --gotta set the list here, as affixes are not ready to be retrieved yet on login
    main_frame.sidePanel.affixDropdown:UpdateAffixList()
    main_frame.sidePanel.affixDropdown:SetAffixWeek(MethodDungeonTools:GetCurrentPreset().week or (MethodDungeonTools:GetCurrentAffixWeek() or 1))
    MethodDungeonTools:UpdateToDungeon(db.currentDungeonIdx)
	main_frame:Hide()

    --Maximize if needed
    if db.maximized then MethodDungeonTools:Maximize() end

    if MethodDungeonTools:IsFrameOffScreen() then
        MethodDungeonTools:ResetMainFramePos()
    end

    framesInitialized = true
end

for k, v in ipairs(dungeonList) do dungeonList[k] = L[v] end
for _, d in pairs(dungeonSubLevels) do for i,vv in pairs(d) do d[i] = L[vv] end end
