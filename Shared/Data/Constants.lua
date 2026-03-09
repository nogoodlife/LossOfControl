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

--@templates
Engine.Data.BACKDROP = {
	bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile     = true, tileSize = 16, edgeSize = 16,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};

--@enum DisplayType
Engine.Data.DisplayType = {
	Full = 2,
	Alert = 1,
	None = 0
};