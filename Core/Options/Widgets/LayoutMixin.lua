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
local Options = Engine.Options;
local Util    = Engine.Util;
local Widgets = Options.Widgets;

--@natives<lua,wow>
local _G       = _G;
local tostring = tostring;
local abs      = math.abs;
local CreateFrame = CreateFrame;

--@class Factory<widgets>
Options.Factory = Options.Factory or {};
local Factory = Options.Factory;

--@internal<util>
local count  = 0;
local prefix = Engine.Name .. "Options";
local function GenerateName(suffix)
	count = count + 1;
	return prefix .. suffix .. count;
end

--@constants
local LAYOUT_LEFT_X = 16;
local LAYOUT_TOP_Y = -16;
local GAP_DEFAULT = -8;
local SCROLL_PADING = 24; -- extra space at bottom
local LAYOUT_ICON_SIZE = 22;
local LAYOUT_ICON_PADING = 4;

-- SECTIONS
local SECTION_PADDING_LEFT = 12;
local SECTION_PADDING_RIGHT = 8;
local SECTION_PADDING_TOP = 10;
local SECTION_PADDING_BOTTOM = 10;
local SECTION_TITLE_GAP = 18;
local SECTION_SPACING = 10; -- gap between sections

-- TEMPLATES
local BACKDROP = Engine.Data.BACKDROP;
local BackdropTemplate = Engine.Compat.BackdropTemplate;

local DROPDOWN_BORDER = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 12,
	insets   = { left = 2, right = 2, top = 2, bottom = 2 },
};
local BACKDROP_MENU = {
	bgFile   = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile     = true, tileSize = 16, edgeSize = 16,
	insets   = { left = 4, right = 4, top = 4, bottom = 4 },
};


-- Widgets dimensions (defaults)
local WIDGET_DROPDOWN_WIDTH = 90;
local WIDGET_SLIDER_WIDTH = 110;
local WIDGET_BUTTON_WIDTH = 120;
local WIDGET_BUTTON_HEIGHT = 22;

-- Widget dimensions (Blizzard templates add internal padding)
local SLIDER_CONTAINER_HEIGHT = 54;

local DROPDOWN_LABEL_OFFSET = -16; -- label sits above the dropdown button
local DROPDOWN_PADDING = 40; -- internal padding
local DROPDOWN_HEIGHT = 26;

-- Flow
local FLOW_RIGHT_GAP = 12;


--# -------------------- Layout --------------------

--@class Layout<mixin>
local Layout = {};
function Factory:Create(panel)
	return setmetatable({
		panel     = panel,
		cursor    = nil,
		content   = nil, -- starting row
		left      = LAYOUT_LEFT_X,
		top       = LAYOUT_TOP_Y,
		overflow  = nil,
		padding   = 0,
		indent    = 0,
		maxHeight = 0,
		absHeight = 0, -- absolute height of content
		-- section;
		stack     = nil,
		section   = nil,
	}, { __index  = Layout });
end


--# -------------------- Content Height --------------------

function Layout:GetContentHeight()
	return self.absHeight;
end

function Layout:GetScrollHeight()
	return self.absHeight + SCROLL_PADING;
end


--# -------------------- Flow Control --------------------

function Layout:NextFlow(padding)
	self.overflow = "right"; -- horizontal
	self.padding = padding or FLOW_RIGHT_GAP;
end

function Layout:Anchor(widget, offsetY, offsetX)
	offsetY = offsetY or GAP_DEFAULT;
	offsetX = offsetX or 0;

	widget:ClearAllPoints();

	local isHorizontal = (self.overflow == "right") and self.cursor;
	if isHorizontal then
		-- Horizontal right of cursor
		widget:SetPoint("LEFT", self.cursor, "RIGHT", self.padding, 0);

		local height = widget:GetHeight() or 0;
		if height > self.maxHeight then
			-- self.maxHeight = height;

			-- local top = self.absHeight - self.maxHeight;
			-- self.absHeight = top + height;
			-- absHeight = top padding + sum(lines)
			self.absHeight = self.absHeight - self.maxHeight + height;
			self.maxHeight = height;
		end

		self.cursor = widget;
		self.overflow = nil;
	elseif self.content then
		-- Vertical below row start
		local extraYOffset = 0;
		local heightLeft = self.content:GetHeight() or 0;
		if self.maxHeight > heightLeft then
			extraYOffset = heightLeft - self.maxHeight;
		end

		widget:SetPoint("TOPLEFT", self.content, "BOTTOMLEFT", -self.indent + offsetX, offsetY + extraYOffset);

		-- local gap = abs(offsetY + extraYOffset);
		local gap = abs(offsetY);
		local height = widget:GetHeight() or 0;

		self.cursor = widget;
		self.content = widget;
		self.indent = 0;
		self.maxHeight = height;
		self.absHeight = self.absHeight + gap + height;
	else
		-- First widget
		widget:SetPoint("TOPLEFT", self.left + offsetX, self.top);

		local height = widget:GetHeight() or 0;

		self.cursor = widget;
		self.content = widget;
		self.indent = 0;
		self.maxHeight = height;
		self.absHeight = abs(self.top) + height;
	end

	return widget;
end

function Layout:Indent(widget, indent)
	if not indent or indent == 0 then
		return;
	end

	local point, parent, relativePoint, sourceX, sourceY = widget:GetPoint(1);
	if not point then
		return;
	end

	widget:ClearAllPoints();
	widget:SetPoint(point, parent, relativePoint, (sourceX or 0) + indent, sourceY or 0);

	self.indent = self.indent + indent;
end


--# -------------------- Decorators --------------------

--- Attaches icon to widget's label text when available
function Layout:AttachIcon(widget, texture)
	if not texture then
		return;
	end

	local anchor = widget.label or widget.Text or widget;
	local icon = widget:CreateTexture(nil, "ARTWORK");
	icon:SetSize(LAYOUT_ICON_SIZE, LAYOUT_ICON_SIZE);
	icon:SetPoint("RIGHT", anchor, "LEFT", -LAYOUT_ICON_PADING, 0);
	icon:SetTexture(texture);
	widget.Icon = icon;
	return icon;
end

function Layout:ApplyBackdrop(widget)
	widget:SetBackdrop(BACKDROP);
	widget:SetBackdropColor(0.06, 0.06, 0.06, 0.45);
	widget:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.45);
end


--# -------------------- Sections --------------------

function Layout:BeginSection(title)
	self.stack = self.stack or {};
	self.stack[#self.stack + 1] = {
		panel     = self.panel,
		cursor    = self.cursor,
		content   = self.content,
		indent    = self.indent,
		maxHeight = self.maxHeight,
		absHeight = self.absHeight,
		left      = self.left,
		top       = self.top,
	};

	local section = CreateFrame("Frame", nil, self.panel, BackdropTemplate);
	self:Anchor(section, -SECTION_SPACING);
	section:SetPoint("RIGHT", self.panel, "RIGHT", -SECTION_PADDING_RIGHT, 0);
	section:SetHeight(1);

	self:ApplyBackdrop(section);

	local contentTop = -SECTION_PADDING_TOP;
	if title then
		local sectionTitle = section:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		sectionTitle:SetPoint("TOPLEFT", SECTION_PADDING_LEFT, -SECTION_PADDING_TOP);
		sectionTitle:SetText(title);
		section.titleText = sectionTitle;

		contentTop = -(SECTION_PADDING_TOP + SECTION_TITLE_GAP);
	end

	-- Switch context into section
	self.panel     = section;
	self.cursor    = nil;
	self.content   = nil;
	self.indent    = 0;
	self.maxHeight = 0;
	self.absHeight = 0;
	self.left      = SECTION_PADDING_LEFT;
	self.top       = contentTop;
	self.section   = section;
end

function Layout:EndSection()
	local stack = self.stack;
	if not stack or #stack == 0 then
		return;
	end

	local totalHeight = self:GetContentHeight() + SECTION_PADDING_BOTTOM;
	self.section:SetHeight(totalHeight);

	-- Restore context
	local saved   = stack[#stack];
	stack[#stack] = nil;
	local section = self.section;

	self.panel     = saved.panel;
	self.cursor    = section;
	self.content   = section;
	self.indent    = 0;
	self.maxHeight = totalHeight;
--	self.absHeight = saved.absHeight;
	self.left      = saved.left;
	self.top       = saved.top;
	self.section   = nil;
	self.absHeight = saved.absHeight + SECTION_SPACING + totalHeight;
end


--# -------------------- Widget Creators --------------------

function Layout:CreateTitle(text)
	local fontString = self.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	self:Anchor(fontString, 0);
	fontString:SetText(text);
	return fontString;
end

function Layout:CreateSubText(text)
	local fontString = self.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	self:Anchor(fontString, -6);
	fontString:SetText(text);
	fontString:SetJustifyH("LEFT");
	fontString:SetNonSpaceWrap(true);
	fontString:SetHeight(64);
	fontString:SetPoint("RIGHT", self.panel, "RIGHT", -32, 0);
	return fontString;
end

function Layout:CreateHeader(text)
	local fontString = self.panel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	self:Anchor(fontString, -18);
	fontString:SetText(text);
	return fontString;
end

function Layout:CreateDescription(text, icon)
	local desc = CreateFrame("Frame", nil, self.panel);
	desc:SetHeight(22);
	self:Anchor(desc, -2);
	desc:SetPoint("RIGHT", self.panel, "RIGHT", -10, 0);

	local xOffest = 4;
	if icon then
		local iconTexture = desc:CreateTexture(nil, "ARTWORK");
		iconTexture:SetSize(LAYOUT_ICON_SIZE, LAYOUT_ICON_SIZE);
		iconTexture:SetPoint("LEFT", xOffest, 0);
		iconTexture:SetTexture(icon);

		xOffest = xOffest + LAYOUT_ICON_SIZE + LAYOUT_ICON_PADING;
	end

	local fontString = desc:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	fontString:SetPoint("LEFT", xOffest, 0);
	fontString:SetPoint("RIGHT", desc, "RIGHT", -4, 0);
	fontString:SetJustifyH("LEFT");
	fontString:SetNonSpaceWrap(true);
	fontString:SetHeight(64);
	fontString:SetTextColor(0.7, 0.7, 0.7);
	fontString:SetText(text);

	desc.text = fontString;
	return desc;
end

function Layout:CreateCheckbox(label, tooltip)
	local name     = GenerateName("Checkbox");
	local checkBox = CreateFrame("CheckButton", name, self.panel, "InterfaceOptionsCheckButtonTemplate");
	self:Anchor(checkBox, -4);

	local text = checkBox.Text or _G[name .. "Text"];
	if text then
		text:SetText(label);
	end

	-- checkBox.tooltipRequirement = tooltip;
	checkBox.tooltipText = tooltip or label;
	return checkBox;
end

function Layout:CreateSlider(label, minVal, maxVal, step, sliderWidth, containerWidth)
	local name      = GenerateName("Slider");
	local container = CreateFrame("Frame", nil, self.panel);
	sliderWidth     = sliderWidth or WIDGET_SLIDER_WIDTH;
	containerWidth  = containerWidth or sliderWidth;

	container:SetSize(containerWidth, SLIDER_CONTAINER_HEIGHT);
	self:Anchor(container, -14);

	local slider = CreateFrame("Slider", name, container, "OptionsSliderTemplate");
	slider:SetPoint("TOPLEFT", 0, -18);
	slider:SetWidth(sliderWidth);
	slider:SetMinMaxValues(minVal, maxVal);
	slider:SetValueStep(step);
	if slider.SetObeyStepOnDrag then
		slider:SetObeyStepOnDrag(true);
	end

	-- self:ApplyBackdrop(container);

	-- OptionsSliderTemplate
	local sliderText = slider.Text or _G[name .. "Text"];
	local sliderLow  = slider.Low  or _G[name .. "Low"];
	local sliderHigh = slider.High or _G[name .. "High"];

	if sliderText then sliderText:SetText(label); end;
	if sliderLow  then sliderLow:SetText(tostring(minVal));  end;
	if sliderHigh then sliderHigh:SetText(tostring(maxVal)); end;

	-- text
	local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	valueText:SetPoint("BOTTOM", 0, -14);
	slider.valueText = valueText;
	slider.label     = sliderText;

	container.slider = slider;
	return slider;
end

function Layout:CreateButton(label, width, height)
	local button = Factory:CreateButton(self.panel, {
		text = label,
		width = width or WIDGET_BUTTON_WIDTH,
		height = height or WIDGET_BUTTON_HEIGHT,
	});
	self:Anchor(button, -12);
	return button;
end

function Layout:CreateDropdown(label, width)
	local container = Factory:CreateDropdownWidget(self.panel, {
		label = label,
		width = width
	});
	self:Anchor(container, -4);
	return container;
end


------------------------------------------------------------
--# Shared Widgets
------------------------------------------------------------
function Factory:CreateLabel(parent, options)
	options = options or {};

	local template = options.fontObject or "GameFontNormal";
	local width    = options.width  or WIDGET_DROPDOWN_WIDTH;
	local height   = options.height or 22;
	local point    = options.point  or "TOPLEFT";
	local relative = options.relativePoint or "BOTTOMLEFT";
	local offsetX  = options.offsetX or 0;
	local offsetY  = options.offsetY or -8;

	local label = parent:CreateFontString(nil, "ARTWORK", template);
	label:SetText(options.text or "");

	if options.anchorTo then
		label:SetPoint(point, options.anchorTo, relative, offsetX, offsetY);
	elseif options.absolutePoint then
		label:SetPoint(options.absolutePoint, options.absoluteX or 0, options.absoluteY or 0);
	end

	return label;
end

function Factory:CreateDropdownWidget(parent, options)
	options = options or {};

	local label = options.label;
	local width = options.width or WIDGET_DROPDOWN_WIDTH;
	local items = options.items or {};
	local value = options.value;

	local name      = GenerateName("Dropdown");
	local container = CreateFrame("Frame", nil, parent);
	local containerWidth = label and (width + DROPDOWN_PADDING) or width;
	container:SetSize(containerWidth, DROPDOWN_HEIGHT);

	if label then
		local text = container:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
		text:SetPoint("LEFT", 16, 0);
		text:SetText(label);
		container.label = text;
	end

	local dd = CreateFrame("Button", name, container);
	dd:SetSize(width, DROPDOWN_HEIGHT);
	dd:SetPoint("TOPLEFT", label and 70 or 0, 0);
	
	local border = CreateFrame("Frame", nil, dd, BackdropTemplate);
	border:SetAllPoints();
	border:SetBackdrop(DROPDOWN_BORDER);
	border:SetBackdropBorderColor(1, 1, 1, 1);

	local selectedText = dd:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	selectedText:SetPoint("LEFT", 6, 0);
	selectedText:SetPoint("RIGHT", -20, 0);
	selectedText:SetJustifyH("LEFT");
	selectedText:SetNonSpaceWrap(true);
	selectedText:SetHeight(64);
	dd.Text = selectedText;

	local arrow = dd:CreateTexture(nil, "ARTWORK");
	arrow:SetSize(12, 18);
	arrow:SetPoint("RIGHT", -8, -4);
	arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Down");

	local menu = CreateFrame("Frame", nil, UIParent, BackdropTemplate);
	menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2);
	menu:SetPoint("TOPRIGHT", dd, "BOTTOMRIGHT", 0, -2);
	menu:SetFrameStrata("DIALOG");
	menu:SetFrameLevel(dd:GetFrameLevel() + 20);
	menu:EnableMouse(true);
	menu:SetClampedToScreen(true);
	menu:Hide();
	
	menu:SetBackdrop(BACKDROP_MENU);
	menu:SetBackdropColor(0.10, 0.10, 0.10, 0.95);
	menu:SetBackdropBorderColor(1, 1, 1, 1);
	
	menu.lines = {};

	Util.Mixin(container, Widgets.DropdownMixin);

	container.dropdown = dd;
	container.menu     = menu;
	container.items    = {};
	container.value    = nil;

	dd:SetScript("OnClick", function() container:Toggle(); end);
	menu:SetScript("OnMouseDown", function() end);

	if #items > 0 then
		container:SetItems(items);
		container:SetSelectedValue(value or items[1].value, true);
	end

	return container;
end

function Factory:CreateInput(parent, options)
	options = options or {};

	local template = options.template or "InputBoxTemplate";
	local width    = options.width  or WIDGET_DROPDOWN_WIDTH;
	local height   = options.height or 22;
	local point    = options.point  or "LEFT";
	local relative = options.relativePoint or "RIGHT";
	local offsetX  = options.offsetX  or 8;
	local offsetY  = options.offsetY  or 0;

	local name  = GenerateName("EditBox");
	local input = CreateFrame("EditBox", name, parent, template);
	input:SetSize(width, height);
	input:SetAutoFocus(options.autoFocus == true);
	input:SetNumeric(options.numeric == true);
	input:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);

	if options.anchorTo then
		input:SetPoint(point, options.anchorTo, relative, offsetX, offsetY);
	end
	if options.maxLetters then
		input:SetMaxLetters(options.maxLetters);
	end
	return input;
end

function Factory:CreateButton(parent, options)
	options = options or {};

	local button = CreateFrame("Button", nil, parent, options.template or "UIPanelButtonTemplate");
	button:SetSize(options.width or WIDGET_BUTTON_WIDTH, options.height or WIDGET_BUTTON_HEIGHT);

	if options.text then
		button:SetText(options.text);
	end

	if options.anchorTo then
		button:SetPoint(
			options.point or "TOPLEFT",
			options.anchorTo,
			options.relativePoint or "BOTTOMLEFT",
			options.offsetX or 0,
			options.offsetY or -8
		);
	elseif options.absolutePoint then
		button:SetPoint(options.absolutePoint, options.absoluteX or 0, options.absoluteY or 0);
	end

	return button;
end