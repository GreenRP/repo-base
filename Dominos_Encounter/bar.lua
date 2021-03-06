local PlayerPowerBarAlt = _G.PlayerPowerBarAlt
if not PlayerPowerBarAlt then return end

local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local EncounterBar = Dominos:CreateClass('Frame', Dominos.Frame)

function EncounterBar:New()
	local f = EncounterBar.proto.New(self, 'encounter')

	f:InitPlayerPowerBarAlt()
	f:ShowInOverrideUI(true)
	f:ShowInPetBattleUI(true)
	f:Layout()

	return f
end

function EncounterBar:GetDefaults()
	return { point = 'CENTER' }
end

-- always reparent + position the bar due to UIParent.lua moving it whenever its shown
function EncounterBar:Layout()
	local bar = self.__PlayerPowerBarAlt
	bar:ClearAllPoints()
	bar:SetParent(self)
	bar:SetPoint('CENTER', self)

	-- resize out of combat
	if not InCombatLockdown() then
		local width, height = bar:GetSize()
		local pW, pH = self:GetPadding()

		width = math.max(width, 36 * 6)
		height = math.max(height, 36)

		self:SetSize(width + pW, height + pH)
	end
end

-- grab a reference to the bar
-- and hook the scripts we need to hook
function EncounterBar:InitPlayerPowerBarAlt()
	if not self.__PlayerPowerBarAlt then
		local bar = PlayerPowerBarAlt

		if bar:GetScript('OnSizeChanged') then
			bar:HookScript('OnSizeChanged', function() self:Layout() end)
		else
			bar:SetScript('OnSizeChanged', function() self:Layout() end)
		end

		self.__PlayerPowerBarAlt = bar
	end
end

function EncounterBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)

	self:AddLayoutPanel(menu)
	self:AddAdvancedPanel(menu)
	menu:AddFadingPanel()

	self.menu = menu

	return menu
end

function EncounterBar:AddLayoutPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)

	panel.scaleSlider = panel:NewScaleSlider()
	panel.paddingSlider = panel:NewPaddingSlider()

	return panel
end

function EncounterBar:AddAdvancedPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Advanced)

	panel:NewClickThroughCheckbox()

	return panel
end

-- exports
Addon.EncounterBar = EncounterBar
