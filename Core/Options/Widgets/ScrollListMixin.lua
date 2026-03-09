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
local Util    = Engine.Util;
local Compat  = Engine.Compat;
local Widgets = Engine.Options.Widgets;

--@natives<lua,wow>
local pairs  = pairs;
local sort   = table.sort;
local wipe   = wipe;
local max    = math.max;
local format = string.format;
local CreateFrame = CreateFrame;

--@constants
local ROW_HEIGHT    = 22;
local ICON_SIZE     = 18;
local SCROLL_HEIGHT = 100;

--@class ScrollListMixin<widgets>
local ScrollListMixin = {};

local function DefaultSort(a, b)
	local nameA = Compat:GetSpellInfo(a) or "";
	local nameB = Compat:GetSpellInfo(b) or "";
	if nameA ~= nameB then
		return nameA < nameB;
	end
	return a < b;
end

function ScrollListMixin:Init(parent, options)
	self.rowHeight      = options.rowHeight or ROW_HEIGHT;
	self.iconSize       = options.iconSize or ICON_SIZE;
	self.sortFunc       = options.sortFunc or DefaultSort;
	self.removeText     = options.removeText or "Remove";
	self.emptyLabel     = options.emptyText or "";
	self.onRemoveOwner  = options.onRemoveOwner;
	self.onRemoveMethod = options.onRemoveMethod;
	self.rows           = {};
	self.sortCache      = {};

	self:CreateScrollFrame(parent, options);
	self:CreateEmptyState();
	self:CreateCounter(parent, options);
	self:CreateRowPool();
end

function ScrollListMixin:CreateScrollFrame(parent, options)
	local scroll = CreateFrame("ScrollFrame", Engine.Name .. options.name, parent, "UIPanelScrollFrameTemplate");
	scroll:SetPoint("TOPLEFT", options.anchorTo, "BOTTOMLEFT", 0, -6);
	scroll:SetPoint("TOPRIGHT", parent, "RIGHT", -30, 0);
	scroll:SetHeight(options.height or SCROLL_HEIGHT);

	local child = CreateFrame("Frame", nil, scroll);
	child:SetWidth(scroll:GetWidth());
	child:SetHeight(1);
	scroll:SetScrollChild(child);
	scroll:SetScript("OnSizeChanged", function(_, w) child:SetWidth(w); end);

	self.scroll = scroll;
	self.child  = child;
end

function ScrollListMixin:CreateEmptyState()
	self.emptyText = self.child:CreateFontString(nil, "ARTWORK", "GameFontDisable");
	self.emptyText:SetPoint("TOP", 0, -12);
	self.emptyText:Hide();
end

function ScrollListMixin:CreateCounter(parent, options)
	self.countText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	if options.countAnchor then
		self.countText:SetPoint("BOTTOMLEFT", options.countAnchor, "TOPLEFT", 0, 4);
	else
		self.countText:SetPoint("BOTTOMLEFT", options.paddingLeft or 18, 16);
	end
end

function ScrollListMixin:CreateRowPool()
	self.pool = Util.CreatePool(
		function() return self:CreateRow(); end,
		function(row)
			row:Hide();
			row:ClearAllPoints();
			row.owner = nil;
			row.key = nil;
		end
	);
end

-- Row
function ScrollListMixin:CreateRow()
	local row = CreateFrame("Frame", nil, self.child);
	row:SetHeight(self.rowHeight);
	row:EnableMouse(true);

	local highlight = row:CreateTexture(nil, "HIGHLIGHT");
	highlight:SetAllPoints();
	Util.SetColorTexture(highlight, 1, 1, 1, 0.08);

	row.icon = row:CreateTexture(nil, "ARTWORK");
	row.icon:SetSize(self.iconSize, self.iconSize);
	row.icon:SetPoint("LEFT", 4, 0);

	row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0);
	row.text:SetPoint("RIGHT", -62, 0);
	row.text:SetJustifyH("LEFT");

	row.removeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate");
	row.removeButton:SetSize(56, 18);
	row.removeButton:SetPoint("RIGHT", -2, 0);
	row.removeButton:SetText(self.removeText);

	row.removeButton:SetScript("OnClick", function(btn)
		local r = btn:GetParent();
		local list = r.owner;
		if not list or r.key == nil then return; end

		local owner = list.onRemoveOwner;
		local method = list.onRemoveMethod;
		if owner and method and owner[method] then
			owner[method](owner, r.key);
		end
	end);

	return row;
end

--# -------------------- Sorting --------------------

function ScrollListMixin:BuildSortedKeys(dataTable)
	local keys = self.sortCache;
	wipe(keys);

	for id in pairs(dataTable) do
		keys[#keys + 1] = id;
	end

	sort(keys, self.sortFunc);
	return keys;
end

--# -------------------- Refresh --------------------

function ScrollListMixin:ReleaseAll()
	for i = 1, #self.rows do
		self.pool.Release(self.rows[i]);
	end
	wipe(self.rows);
end

--- Refresh(dataTable, formatterOwner, formatterMethodName, counterFmt)
function ScrollListMixin:Refresh(dataTable, owner, methodName, counterFmt)
	self:ReleaseAll();

	local keys = self:BuildSortedKeys(dataTable);
	local yOffset = 0;

	for i = 1, #keys do
		local spellID = keys[i];
		local row = self.pool.Acquire();

		row.owner = self;
		row.key = spellID;
		row:SetPoint("TOPLEFT", 0, yOffset);
		row:SetPoint("RIGHT");
		row:Show();

		local _, iconTexture = Compat:GetSpellInfo(spellID);
		row.icon:SetTexture(iconTexture or Compat.FALLBACK_ICON);
		row.text:SetText(owner[methodName](owner, spellID, dataTable[spellID]));

		self.rows[i] = row;
		yOffset = yOffset - self.rowHeight;
	end

	self:UpdateCounter(#keys, counterFmt);
end

function ScrollListMixin:UpdateCounter(count, counterFmt)
	self.child:SetHeight(max(1, count * self.rowHeight));
	self.countText:SetText(format(counterFmt, count));

	if count == 0 then
		self.emptyText:SetText(self.emptyLabel);
		self.emptyText:Show();
	else
		self.emptyText:Hide();
	end
end

--# -------------------- Public Constructor --------------------

Widgets.ScrollList = {
	Create = function(_, parent, options)
		options = options or {};
		local list = setmetatable({}, { __index = ScrollListMixin });
		list:Init(parent, options);
		return list;
	end,
};