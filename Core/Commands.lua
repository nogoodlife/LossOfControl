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

--@class Commands<core>
local Commands = {};
Engine.Commands = Commands;


-- Initialization
----------------------------------------------------------------
function Commands:Init()
	-- Slash: /loc auras — open Custom Auras panel (independent of options)
	SLASH_LOC1 = "/loc";
	SLASH_LOC2 = "/los";

	SlashCmdList.LOC = function(msg)
		Commands:Handle(msg);
	end
end

function Commands:Handle(msg)
	local cmd = (msg or ""):match("^%s*(%S*)") or "";
	if cmd == "auras" or cmd == "custom" then
		Engine.Options:OpenAuraManager();
	else
		Engine.Options:Open();
	end
end