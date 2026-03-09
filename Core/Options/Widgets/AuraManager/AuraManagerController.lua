--[[
 Copyright (c) 2026 s0high
 https://github.com/s0h2x/LossOfControl
    
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
]]

--@class Engine<ns>
local Engine = select(2, ...);

--@import<ns>
local Compat     = Engine.Compat;
local Dispatch   = Engine.Dispatcher;
local Util       = Engine.Util;
local Factory    = Engine.Options.Factory;
local Widgets    = Engine.Options.Widgets;
local ScrollList = Widgets.ScrollList;

--@natives<lua,wow>
local format      = string.format;
local tonumber    = tonumber;
local CreateFrame = CreateFrame;

--@constants
local SECTION_PAD = 18;
local AURA_LIST_HEIGHT = 120;
local INTERRUPT_LIST_HEIGHT = 60;

-- local L; -- Locale is immutable per session — cache once, use everywhere.

--@class AuraManagerControllerMixin<mixin>
local AuraManagerControllerMixin = {};

function AuraManagerControllerMixin:OnLoad(dataModel, localeId, ccTypeChoices)
	self.L = localeId;
	self.ccTypeChoices = ccTypeChoices or {};
	
	self:SetDataModel(dataModel);

    self:OnCreated();
	self:CreateWidgets();
	self:BindScripts();
end

function AuraManagerControllerMixin:SetDataModel(dataModel)
	self.dataModel = dataModel;
end

function AuraManagerControllerMixin:OnCreated()
	self:Hide();
	
	self:RegisterForDrag("LeftButton");
	self:SetScript("OnDragStart", self.StartMoving);
	self:SetScript("OnDragStop", self.StopMovingOrSizing);

	self:SetSize(420, 560);
	self:SetPoint("CENTER", -60, 10);
	self:SetFrameStrata("DIALOG");
	self:EnableMouse(true);
	self:SetClampedToScreen(true);
	self:SetMovable(true);
 
	self:SetBackdrop(Engine.Data.BACKDROP);
	self:SetBackdropColor(0.06, 0.06, 0.06, 0.92);
end

--# -------------------- Events --------------------

function AuraManagerControllerMixin:OnShow()
	self:Refresh();
end

function AuraManagerControllerMixin:OnTrackerDataUpdate()
	self:Refresh();
end

--# -------------------- Helpers --------------------

function AuraManagerControllerMixin:FormatAuraRow(spellID, ccType)
	local name = Compat:GetSpellInfo(spellID) or self.L.OPT_UNKNOWN;
	return format("[%d]  %s  =  %s", spellID, name, self.L[ccType] or ccType);
end

function AuraManagerControllerMixin:FormatInterruptRow(spellID, duration)
	local name = Compat:GetSpellInfo(spellID) or self.L.OPT_UNKNOWN;
	return format("[%d]  %s  =  %d %s", spellID, name, duration, self.L.SECONDS);
end

function AuraManagerControllerMixin:SetStatusText(parent, text)
	if text then
		parent:SetText("|cffff9900" .. text .. "|r");
		parent:Show();
	else
		parent:Hide();
	end
end

function AuraManagerControllerMixin:GetInputNumber(inputBox)
	local value = tonumber(inputBox:GetText());
	return (value and value > 0) and value or nil;
end

function AuraManagerControllerMixin:ResetInput(inputBox)
	inputBox:SetText("");
	inputBox:ClearFocus();
end

function AuraManagerControllerMixin:CreateStatusText()
	local text = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	text:SetJustifyH("LEFT");
	text:SetTextColor(1, 0.4, 0.4);
	text:Hide();
	return text;
end

function AuraManagerControllerMixin:CreatePreviewText()
	local text = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	text:SetJustifyH("LEFT");
	text:SetTextColor(0.6, 0.6, 0.6);
	return text;
end

function AuraManagerControllerMixin:CreateSeparator(anchorTo)
	local sep = self:CreateTexture(nil, "ARTWORK");
	sep:SetHeight(1);
	sep:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -10);
	sep:SetPoint("RIGHT", self, "RIGHT", -SECTION_PAD, 0);

	Util.SetColorTexture(sep, 0.4, 0.4, 0.4, 0.8);
	return sep;
end

function AuraManagerControllerMixin:BuildCCTypeItems()
	local items = {};
	local types = self.ccTypeChoices;

	for i = 1, #types do
		local ccType = types[i];
		items[i] = {
			value = ccType,
			text = self.L[ccType] or ccType,
		};
	end

	return items;
end

--# -------------------- Aura Handlers --------------------

function AuraManagerControllerMixin:OnAuraSpellChanged(inputBox)
	local spellID = self:GetInputNumber(inputBox);
	if spellID then
		self.AuraPreview:SetText(
			Compat:GetSpellInfo(spellID) or ("|cffff4444" .. self.L.OPT_UNKNOWN .. "|r")
		);
	else
		self.AuraPreview:SetText("");
	end

	local warn = self.dataModel:IsBuiltInAura(spellID) and self.L.OPT_ALREADY_IN_CC or nil;
	self:SetStatusText(self.AuraStatus, warn);
end

function AuraManagerControllerMixin:OnAuraSpellEnter(inputBox)
	self.AddAuraButton:Click();
	inputBox:ClearFocus();
end

function AuraManagerControllerMixin:OnAddAura()
	local spellID = self:GetInputNumber(self.AuraSpellInput);
	if not spellID then
		return;
	end

	self.dataModel:AddAura(spellID, self.TypeDropdown:GetSelectedValue());
	self:ResetInput(self.AuraSpellInput);
	self.AuraPreview:SetText("");
end

function AuraManagerControllerMixin:RemoveAura(spellID)
	self.dataModel:RemoveAura(spellID);
end

--# -------------------- Interrupt Handlers --------------------

function AuraManagerControllerMixin:OnInterruptSpellChanged(inputBox)
	local spellID = self:GetInputNumber(inputBox);
	local warn = self.dataModel:IsBuiltInInterrupt(spellID) and self.L.OPT_ALREADY_IN_INTERRUPT or nil;
	self:SetStatusText(self.InterruptStatus, warn);
end

function AuraManagerControllerMixin:OnAddInterrupt()
	local spellID = self:GetInputNumber(self.InterruptSpellInput);
	local duration = self:GetInputNumber(self.DurationInput);
	if not spellID or not duration then
		return;
	end

	self.dataModel:AddInterrupt(spellID, duration);
	self:ResetInput(self.InterruptSpellInput);
	self:ResetInput(self.DurationInput);
end

function AuraManagerControllerMixin:RemoveInterrupt(spellID)
	self.dataModel:RemoveInterrupt(spellID);
end

--# -------------------- Clear Handlers --------------------

function AuraManagerControllerMixin:OnClearAuras()
	self.dataModel:ClearAuras();
end

function AuraManagerControllerMixin:OnClearInterrupts()
	self.dataModel:ClearInterrupts();
end

--# -------------------- Refresh --------------------

function AuraManagerControllerMixin:Refresh()
	self.AuraList:Refresh(self.dataModel:GetAuras(), self, "FormatAuraRow", "Total: %d");
	self.InterruptList:Refresh(self.dataModel:GetInterrupts(), self, "FormatInterruptRow", "Interrupts: %d");
end

--# -------------------- Widgets --------------------

function AuraManagerControllerMixin:CreateWidgets()
	self:CreateHeader();
	self:CreateAuraSection();
	self:CreateInterruptSection();
	self:CreateFooter();
end

function AuraManagerControllerMixin:CreateHeader()
	local closeButton = CreateFrame("Button", nil, self, "UIPanelCloseButton");
	closeButton:SetPoint("TOPRIGHT", -5, -5);

	self.TitleText = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	self.TitleText:SetPoint("TOP", 0, -14);
	self.TitleText:SetText(self.L.OPT_AURA_MANAGER);
end

function AuraManagerControllerMixin:CreateAuraSection()
	local L = self.L;

	local sectionHeader = Factory:CreateLabel(self, {
		text = L.OPT_CUSTOM_AURAS,
		absolutePoint = "TOPLEFT",
		absoluteX = SECTION_PAD,
		absoluteY = -44,
	});

	self.AuraPreview = self:CreatePreviewText();
	self.AuraStatus = self:CreateStatusText();

	local spellLabel = Factory:CreateLabel(self, {
		text = self.L.OPT_SPELL_ID,
		anchorTo = sectionHeader,
		offsetY = -6,
	});

	self.AuraSpellInput = Factory:CreateInput(self, {
		numeric = true,
		anchorTo = spellLabel,
		maxLetters = 6,
	});

	self.AuraPreview:SetPoint("LEFT", self.AuraSpellInput, "RIGHT", 8, 0);
	self.AuraPreview:SetPoint("RIGHT", self, "RIGHT", -SECTION_PAD, 0);

	self.AuraStatus:SetPoint("TOPLEFT", self.AuraSpellInput, "BOTTOMLEFT", 0, -2);
	self.AuraStatus:SetPoint("RIGHT", self, "RIGHT", -SECTION_PAD, 0);

	local typeLabel = Factory:CreateLabel(self, {
		text = self.L.OPT_TYPE,
		anchorTo = spellLabel,
		offsetY = -28,
	})

	self.TypeDropdown = Factory:CreateDropdownWidget(self, {
		width = 140,
		items = self:BuildCCTypeItems(),
		value = self.ccTypeChoices[1],
	});
	self.TypeDropdown:SetPoint("LEFT", typeLabel, "RIGHT", 8, -2);

	self.AddAuraButton = Factory:CreateButton(self, {
		text = L.OPT_ADD_AURA,
		width = 110,
		height = 24,
		anchorTo = typeLabel,
		point = "TOPLEFT",
		relativePoint = "BOTTOMLEFT",
		offsetY = -14,
	});

	local sep = self:CreateSeparator(self.AddAuraButton);
	local header = Factory:CreateLabel(self, {
		text = L.OPT_CURRENT_AURAS,
		anchorTo = sep,
		offsetY = -6,
	});

	self.AuraList = ScrollList:Create(self, {
		name = "AuraPanelScrollListAuras",
		anchorTo = header,
		height = AURA_LIST_HEIGHT,
		paddingLeft = SECTION_PAD,
		removeText = L.OPT_REMOVE,
		emptyText = L.OPT_NO_CUSTOM_AURAS,
		onRemoveOwner = self,
		onRemoveMethod = "RemoveAura",
	});
end

function AuraManagerControllerMixin:CreateInterruptSection()
	local L = self.L;

	local sep = self:CreateSeparator(self.AuraList.scroll);
	local sectionHeader = Factory:CreateLabel(self, {
		text = L.OPT_CUSTOM_INTERRUPTS,
		anchorTo = sep,
		offsetY = -6,
	});

	self.InterruptStatus = self:CreateStatusText();

	local spellLabel = Factory:CreateLabel(self, {
		text = self.L.OPT_SPELL_ID,
		anchorTo = sectionHeader,
	});

	self.InterruptSpellInput = Factory:CreateInput(self, {
		numeric = true,
		anchorTo = spellLabel,
		maxLetters = 6,
	});

	self.InterruptStatus:SetPoint("TOPLEFT", spellLabel, "BOTTOMLEFT", 0, -2);
	self.InterruptStatus:SetPoint("RIGHT", self, "RIGHT", -SECTION_PAD, 0);

	local durationLabel = Factory:CreateLabel(self, { text = L.OPT_DURATION });
	durationLabel:SetPoint("LEFT", self.InterruptSpellInput, "RIGHT", 16, 0);

	self.DurationInput = Factory:CreateInput(self, {
		numeric = true,
		width = 60,
		anchorTo = durationLabel,
		maxLetters = 3,
	});

	self.AddInterruptButton = Factory:CreateButton(self, {
		text = L.OPT_ADD_INTERRUPT,
		width = 110, height = 24,
		anchorTo = spellLabel,
		offsetY = -24,
	});

	local header = Factory:CreateLabel(self, {
		text = L.OPT_CURRENT_INTERRUPTS,
		anchorTo = self.AddInterruptButton,
		offsetY = -6,
	});

	self.InterruptList = ScrollList:Create(self, {
		name = "AuraPanelScrollListInterrupts",
		anchorTo = header,
		height = INTERRUPT_LIST_HEIGHT,
		countAnchor = self.AuraList.countText,
		paddingLeft = SECTION_PAD,
		removeText = L.OPT_REMOVE,
		emptyText = L.OPT_NO_CUSTOM_INTERRUPTS,
		onRemoveOwner = self,
		onRemoveMethod = "RemoveInterrupt",
	});
end

function AuraManagerControllerMixin:CreateFooter()
	local L = self.L;

	self.ClearAurasButton = Factory:CreateButton(self, {
		text = L.OPT_CLEAR_AURAS,
		absolutePoint = "BOTTOMRIGHT",
		absoluteX = -14,
		absoluteY = 12,
	});

	self.ClearInterruptsButton = Factory:CreateButton(self, {
		text = L.OPT_CLEAR_INTERRUPTS,
		width = 110,
	});
	self.ClearInterruptsButton:SetPoint("RIGHT", self.ClearAurasButton, "LEFT", -8, 0);
end

--# -------------------- Script Binding --------------------

function AuraManagerControllerMixin:BindScripts()
	Util.BindScript(self.AuraSpellInput, "OnTextChanged", self, "OnAuraSpellChanged");
	Util.BindScript(self.AuraSpellInput, "OnEnterPressed", self, "OnAuraSpellEnter");
	Util.BindScript(self.AddAuraButton, "OnClick", self, "OnAddAura");

	Util.BindScript(self.InterruptSpellInput, "OnTextChanged", self, "OnInterruptSpellChanged");
	Util.BindScript(self.AddInterruptButton, "OnClick", self, "OnAddInterrupt");

	Util.BindScript(self.ClearAurasButton, "OnClick", self, "OnClearAuras");
	Util.BindScript(self.ClearInterruptsButton, "OnClick", self, "OnClearInterrupts");

	self:SetScript("OnShow", self.OnShow);

	Dispatch:RegisterEvent("TRACKER_DATA_UPDATE", self, "OnTrackerDataUpdate");
end

--@export<ns>
Widgets.AuraManagerControllerMixin = AuraManagerControllerMixin;