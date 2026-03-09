--[[
 Copyright (c) 2026 s0high
 https://github.com/s0h2x/LossOfControl
    
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
]]

--@class Engine<ns>
local AddOnName, Engine = ...;

--@natives<lua,wow>
local format = string.format;
local print = print;
local tostring = tostring;
local select = select;
local CreateFrame = CreateFrame;

--@compat
local function GetMetadata(name, field)
	local fn = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata;
	return fn and fn(name, field);
end


--@metadata<engine>
Engine.Name	   = AddOnName;
Engine.Title   = GetMetadata(AddOnName, "Title") or AddOnName;
Engine.Author  = GetMetadata(AddOnName, "Author");
Engine.Version = GetMetadata(AddOnName, "Version");
Engine.Notes   = GetMetadata(AddOnName, "Notes");
Engine.Website = GetMetadata(AddOnName, "X-Website");
Engine.Debug   = false; -- Set true to see debug prints, developer flag


--@namespaces
Engine.Data	= Engine.Data or {};
Engine.Util	= Engine.Util or {};
Engine.API  = Engine.API  or {};
Engine.Shared  = Engine.Shared or {};
Engine.Modules = Engine.Modules or {};
Engine.Options = Engine.Options or {};


--@utils
local LOG_PREFIX = (Engine.Title) .. " \194\187 ";
Engine.Log = function(msg, ...)
	if select("#", ...) > 0 then
		print(LOG_PREFIX .. format(msg, ...));
	else
		print(LOG_PREFIX .. tostring(msg));
	end
end

Engine.DebugLog = function(msg, ...)
	if Engine.Debug then
		Engine.Log("|cff804a00[DEBUG]|r " .. msg, ...);
	end
end

--@media
local ADDON_PATH = "Interface\\AddOns\\" .. AddOnName;
Engine.Media = Engine.Media or {
	SOUND_ALERT = ADDON_PATH .. "\\Resources\\Sound\\alert_ma_arcanemissles.ogg",
};

--@loader
local loader = CreateFrame("Frame");
loader:RegisterEvent("ADDON_LOADED");
loader:RegisterEvent("PLAYER_LOGIN");
loader:SetScript("OnEvent", function(self, event, arg1)
	if (event == "ADDON_LOADED" and arg1 == AddOnName) then
		Engine.DB:Init();
		Engine.Localization:Init();
	elseif (event == "PLAYER_LOGIN") then
		-- Frame/UI
		local module = Engine.Modules;

		local tracker = module.LossOfControlTracker;
		tracker:Init();

		local controller = module.LossOfControlFrameMixin;
		controller:OnLoad();

		-- Options
		Engine.Options:Init(controller, module.Schema);
		Engine.Commands:Init();

		-- Clean
		self:UnregisterAllEvents();
		self:SetScript("OnEvent", nil);
		loader = nil;
	end
end);

-- Engine.Loader = loader;