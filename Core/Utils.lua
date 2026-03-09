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
local Util = Engine.Util;

--@natives<lua>
local pairs = pairs;
local floor = math.floor;
local max = math.max;
local min = math.min;
local tremove = table.remove;
local tinsert = table.insert;
local tostring = tostring;
local type = type;


-- Table
----------------------------------------------------------------
function Util.Merge(dst, src, overwrite)
	if not (dst and src) then
		return dst;
	end
	if overwrite == nil then overwrite = true; end
	for k, v in pairs(src) do
		if overwrite or dst[k] == nil then
			dst[k] = v;
		end
	end
	return dst;
end

function Util.Mixin(dst, mixin)
	return Util.Merge(dst, mixin, true);
end


-- Pools
----------------------------------------------------------------
function Util.CreatePool(createFunc, resetFunc)
	local pool = {};
	return {
		Acquire = function()
			local obj = tremove(pool);
			if obj then return obj; end
			return createFunc();
		end,
		Release = function(obj)
			if resetFunc then
				resetFunc(obj);
			end
			tinsert(pool, obj);
		end,
	};
end

-- Math
----------------------------------------------------------------
function Util.Clamp(value, minVal, maxVal)
	return min(max(value, minVal), maxVal);
end

function Util.Clamp01(value)
	return min(max(value, 0), 1);
end

function Util.Round(value, decimals)
	if not decimals or decimals == 0 then
		return floor(value + 0.5);
	end
	local mult = 10 ^ decimals;
	return floor(value * mult + 0.5) / mult;
end


-- Interface
----------------------------------------------------------------
function Util.SetShown(region, shown)
	if not region then return; end
	if shown then
		region:Show();
	else
		region:Hide();
	end
end

function Util.SetMultipleShown(shown, ...)
	local method = shown and "Show" or "Hide";
	for i = 1, select("#", ...) do
		local region = select(i, ...);
		if region then
			region[method](region);
		end
	end
end

function Util.SetColorTexture(obj, colorR, colorG, colorB, a)
	if not obj:GetTexture() then
		obj:SetTexture("Interface\\Buttons\\WHITE8x8");
	end
	obj:SetVertexColor(colorR, colorG, colorB, a);
end

-- Scripts
----------------------------------------------------------------
-- Util.BindScript(widget, scriptName, owner, methodName)
function Util.BindScript(widget, scriptName, owner, methodName)
	widget:SetScript(scriptName, function(self, ...)
		owner[methodName](owner, self, ...);
	end);
end


-- CombatLog
----------------------------------------------------------------
function Util.GetSchoolString(schoolMask)
	if _G.CombatLog_String_SchoolString then
		return _G.CombatLog_String_SchoolString(schoolMask);
	end
	return tostring(schoolMask or 0);
end


-- Cooldown
----------------------------------------------------------------
function Util.SetCooldown(cd, start, duration, drawEdge)
	if start and start > 0 and duration and duration > 0 then
		cd:SetDrawEdge(drawEdge or false);
		cd:SetCooldown(start, duration);
		cd:Show();
	else
		cd:Hide();
	end
end


-- Animations
----------------------------------------------------------------
function Util.AnimateScaleText(text, timings, elapsed)
	local scrollTime = text.scrollTime;
	if not scrollTime then return; end

	scrollTime = scrollTime + elapsed;
	text.scrollTime = scrollTime;

	local scaleUpTime = timings.RAID_NOTICE_SCALE_UP_TIME;
	local scaleDownTime = timings.RAID_NOTICE_SCALE_DOWN_TIME;
	local minHeight = timings.RAID_NOTICE_MIN_HEIGHT;
	local maxHeight = timings.RAID_NOTICE_MAX_HEIGHT;
	local heightDiff = maxHeight - minHeight;

	if scrollTime <= scaleUpTime then
		local progress = scrollTime / scaleUpTime;
		text:SetTextHeight(floor(minHeight + heightDiff * progress));
	elseif scrollTime <= scaleDownTime then
		local progress = (scrollTime - scaleUpTime) / (scaleDownTime - scaleUpTime);
		text:SetTextHeight(floor(maxHeight - heightDiff * progress));
	else
		text:SetTextHeight(minHeight);
		text.scrollTime = nil;
	end
end

local ALERT_FADE_DELAY = 1.0;
local ALERT_FADE_TIME = 0.5;
function Util.ProcessFade(frame, elapsed)
	if frame.fadeDelayTime then
		frame.fadeDelayTime = frame.fadeDelayTime - elapsed;
		if frame.fadeDelayTime <= 0 then
			frame.fadeDelayTime = nil;
		end
		return true;
	end

	if frame.fadeTime and not frame.fadeDelayTime then
		frame.fadeTime = frame.fadeTime - elapsed;
		if frame.fadeTime <= 0 then
			frame:Hide();
			return false;
		end

		frame:SetAlpha(Util.Clamp01(frame.fadeTime / ALERT_FADE_TIME));
		return true;
	end

	frame:SetAlpha(1.0);
	return false;
end