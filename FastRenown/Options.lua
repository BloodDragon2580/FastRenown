local ADDON_NAME, ns = ...
local L = ns.L
local LibDBIcon = LibStub("LibDBIcon-1.0")

local function RefreshMinimapIcon()
    if ns.db.minimap.hide then
        LibDBIcon:Hide("FastRenown")
    else
        LibDBIcon:Show("FastRenown")
    end
end

local function CreateCheckButton(parent, text)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb.Text:SetText(text)
    return cb
end

local function RegisterOptions()
    local panel = CreateFrame("Frame")
    panel.name = L.ADDON_TITLE

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.ADDON_TITLE)

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText(L.ADDON_DESC)

    local showButton = CreateCheckButton(panel, L.SHOW_MINIMAP_BUTTON)
    showButton:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -2, -18)
    showButton:SetScript("OnClick", function(self)
        ns.db.minimap.hide = not self:GetChecked()
        RefreshMinimapIcon()
    end)

    local lockButton = CreateCheckButton(panel, L.LOCK_MINIMAP_BUTTON)
    lockButton:SetPoint("TOPLEFT", showButton, "BOTTOMLEFT", 0, -8)
    lockButton:SetScript("OnClick", function(self)
        ns.db.minimap.lock = self:GetChecked() and true or false
    end)

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetSize(160, 24)
    resetButton:SetPoint("TOPLEFT", lockButton, "BOTTOMLEFT", 0, -20)
    resetButton:SetText(L.RESET_SETTINGS)
    resetButton:SetScript("OnClick", function()
        ns.db.minimap.hide = ns.defaults.minimap.hide
        ns.db.minimap.minimapPos = ns.defaults.minimap.minimapPos
        ns.db.minimap.radius = ns.defaults.minimap.radius
        ns.db.minimap.lock = ns.defaults.minimap.lock

        showButton:SetChecked(not ns.db.minimap.hide)
        lockButton:SetChecked(ns.db.minimap.lock)

        RefreshMinimapIcon()
    end)

    panel:SetScript("OnShow", function()
        showButton:SetChecked(not ns.db.minimap.hide)
        lockButton:SetChecked(ns.db.minimap.lock)
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
        Settings.RegisterAddOnCategory(category)
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    RegisterOptions()
end)
