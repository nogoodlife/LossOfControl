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
local Dispatch = Engine.Dispatcher;
local Data     = Engine.Data;
local Widgets  = Engine.Options.Widgets;

--@natives<lua>
local wipe = wipe;

--@class AuraManagerDataMixin<mixin>
local AuraManagerDataMixin = {};

function AuraManagerDataMixin:Init(data)
	assert(data, "AuraData: Data model must be provided");

	self.data = data;
	data.customAuras = data.customAuras or {};
	data.customInterrupts = data.customInterrupts or {};
end

function AuraManagerDataMixin:NotifyUpdate()
	Dispatch:FireEvent("TRACKER_DATA_UPDATE");
end

function AuraManagerDataMixin:GetAuras()
	return self.data.customAuras;
end

function AuraManagerDataMixin:GetInterrupts()
	return self.data.customInterrupts;
end

function AuraManagerDataMixin:AddAura(spellID, ccType, silent)
	self.data.customAuras[spellID] = ccType;
	if not silent then
		self:NotifyUpdate();
	end
end

function AuraManagerDataMixin:RemoveAura(spellID)
	self.data.customAuras[spellID] = nil;
	self:NotifyUpdate();
end

function AuraManagerDataMixin:ClearAuras()
	wipe(self.data.customAuras);
	self:NotifyUpdate();
end

function AuraManagerDataMixin:AddInterrupt(spellID, duration)
	self.data.customInterrupts[spellID] = duration;
	self:NotifyUpdate();
end

function AuraManagerDataMixin:RemoveInterrupt(spellID)
	self.data.customInterrupts[spellID] = nil;
	self:NotifyUpdate();
end

function AuraManagerDataMixin:ClearInterrupts()
	wipe(self.data.customInterrupts);
	self:NotifyUpdate();
end

function AuraManagerDataMixin:IsBuiltInAura(spellID)
	return spellID and spellID > 0 and Data.AURA_CC[spellID] ~= nil;
end

function AuraManagerDataMixin:IsBuiltInInterrupt(spellID)
	return spellID and spellID > 0 and Data.INTERRUPT_LOCKOUT[spellID] ~= nil;
end

--@export<ns>
Widgets.AuraManagerDataMixin = AuraManagerDataMixin;