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
local Compat  = Engine.Compat;
local Util    = Engine.Util;
local Widgets = Engine.Options.Widgets;

--@natives<lua,wow>
local CreateFrame = CreateFrame;
local UIParent    = UIParent;

--@class AuraManager<manager>
local AuraManager = {};
local mainFrame;

function AuraManager:Show(dataModel, locale, ccTypeChoices)
	if not mainFrame then
		mainFrame = CreateFrame("Frame", Engine.Name .. "AuraManagerFrame", UIParent, Compat.BackdropTemplate);
		Util.Mixin(mainFrame, Widgets.AuraManagerControllerMixin);
		mainFrame:OnLoad(dataModel, locale, ccTypeChoices);
	else
		mainFrame:SetDataModel(dataModel);
	end

	mainFrame:Show();
	return mainFrame;
end

function AuraManager:Hide()
	if mainFrame then
		mainFrame:Hide();
	end
end

--@export<ns>
Widgets.AuraManager = AuraManager;