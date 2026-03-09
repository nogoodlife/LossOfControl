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

--@class Compat<util>
local Compat = {};

function Compat:HasModernSettings()
	return Settings
	   and Settings.RegisterVerticalLayoutCategory
	   and Settings.RegisterAddOnCategory
	   and Settings.OpenToCategory
	   and true or false;
end

function Compat:CreateSettingsSlider(category, setting, minVal, maxVal, step)
	if not Settings or not Settings.CreateSlider then
		return;
	end

	if Settings.CreateSliderOptions then
		local options = Settings.CreateSliderOptions(minVal, maxVal, step);
		return Settings.CreateSlider(category, setting, options);
	end

	-- Fallback: direct arguments (10.x+)
	return Settings.CreateSlider(category, setting, minVal, maxVal, step);
end

function Compat:CreateSettingsDropdown(category, setting, items, tooltip)
	if not Settings or not Settings.CreateDropdown then
		return;
	end

	--> Midnight (12.x): CreateDropdownOptions
	if Settings.CreateDropdownOptions then
		local options = Settings.CreateDropdownOptions();
		for i = 1, #items do
			options:Add(items[i].value, items[i].text);
		end
		return Settings.CreateDropdown(category, setting, options, tooltip);
	end

	--> Dragonflight (10.x+): CreateControlTextContainer
	if Settings.CreateControlTextContainer then
		local function GetOptions()
			local container = Settings.CreateControlTextContainer();
			for i = 1, #items do
				container:Add(items[i].value, items[i].text);
			end
			return container:GetData();
		end
		return Settings.CreateDropdown(category, setting, GetOptions, tooltip);
	end
end

--@export<ns>
Engine.Options.Compat = Compat;