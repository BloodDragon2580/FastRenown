local ADDON_NAME, ns = ...
local L = ns.L

local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local defaults = {
    iconFileID = 236681,
    minimap = {
        hide = false,
        minimapPos = 215,
        radius = 78,
        lock = false,
    },
}

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then
        return {}
    end
    if type(dst) ~= "table" then
        dst = {}
    end

    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end

    return dst
end

local function GetMajorFactionIDsSafe()
    if C_MajorFactions and type(C_MajorFactions.GetMajorFactionIDs) == "function" then
        local ok, ids = pcall(C_MajorFactions.GetMajorFactionIDs)
        if ok and type(ids) == "table" then
            return ids
        end
    end

    return {}
end

local function GetMajorFactionDataSafe(factionID)
    if C_MajorFactions and type(C_MajorFactions.GetMajorFactionData) == "function" then
        local ok, data = pcall(C_MajorFactions.GetMajorFactionData, factionID)
        if ok and type(data) == "table" then
            return data
        end
    end

    return nil
end

local function GetRenownLevelSafe(factionID)
    if not C_MajorFactions then
        return nil
    end

    if type(C_MajorFactions.GetCurrentRenownLevel) == "function" then
        local ok, level = pcall(C_MajorFactions.GetCurrentRenownLevel, factionID)
        if ok and level then
            return level
        end
    end

    if type(C_MajorFactions.GetMajorFactionRenownInfo) == "function" then
        local ok, info = pcall(C_MajorFactions.GetMajorFactionRenownInfo, factionID)
        if ok and type(info) == "table" then
            return info.level or info.renownLevel
        end
    end

    local data = GetMajorFactionDataSafe(factionID)
    if data then
        return data.renownLevel or data.level
    end

    return nil
end

local function GetMapInfoSafe(mapID)
    if not mapID or not (C_Map and C_Map.GetMapInfo) then
        return nil
    end

    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if ok and type(info) == "table" then
        return info
    end

    return nil
end

local function GetCurrentExpansionID()
    if not (C_Map and C_Map.GetBestMapForUnit) then
        return nil
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    local visited = {}
    local bestExpansionID = nil

    while mapID and not visited[mapID] do
        visited[mapID] = true

        local info = GetMapInfoSafe(mapID)
        if not info then
            break
        end

        if info.expansionID ~= nil and info.expansionID >= 0 then
            bestExpansionID = info.expansionID
            break
        end

        mapID = info.parentMapID
    end

    if bestExpansionID ~= nil then
        return bestExpansionID
    end

    local highestExpansionID = nil
    for _, factionID in ipairs(GetMajorFactionIDsSafe()) do
        local data = GetMajorFactionDataSafe(factionID)
        local level = GetRenownLevelSafe(factionID)
        local expansionID = data and data.expansionID

        if level and expansionID ~= nil and expansionID >= 0 then
            if highestExpansionID == nil or expansionID > highestExpansionID then
                highestExpansionID = expansionID
            end
        end
    end

    return highestExpansionID
end

local function GetKnownRenownFactions()
    local factions = {}
    local currentExpansionID = GetCurrentExpansionID()

    if currentExpansionID == nil then
        return factions
    end

    for _, factionID in ipairs(GetMajorFactionIDsSafe()) do
        local data = GetMajorFactionDataSafe(factionID)
        local level = GetRenownLevelSafe(factionID)

        if data and data.name and level and data.expansionID == currentExpansionID then
            factions[#factions + 1] = {
                id = factionID,
                name = data.name,
                level = level,
                expansionID = data.expansionID,
            }
        end
    end

    table.sort(factions, function(a, b)
        if a.level == b.level then
            return a.name < b.name
        end
        return a.level > b.level
    end)

    return factions
end

local dataObject = LibDataBroker:NewDataObject("FastRenown", {
    type = "launcher",
    text = "Renown",
    icon = defaults.iconFileID,
})

function dataObject:OnClick(button)
    return
end

function dataObject:OnTooltipShow()
    self:AddLine(L.TOOLTIP_TITLE, 1, 0.82, 0)
    self:AddLine(" ")

    local factions = GetKnownRenownFactions()
    if #factions == 0 then
        self:AddLine(L.TOOLTIP_NONE, 0.75, 0.75, 0.75)
    else
        self:AddLine(L.TOOLTIP_RENOWN, 1, 1, 1)
        for _, info in ipairs(factions) do
            self:AddDoubleLine(info.name, string.format(L.RENOWN_LEVEL_FORMAT, info.level), 0.9, 0.9, 0.9, 1, 0.82, 0)
        end
    end
end

ns.defaults = defaults
ns.GetKnownRenownFactions = GetKnownRenownFactions
ns.dataObject = dataObject

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        FRB = CopyDefaults(defaults, FRB or {})
        ns.db = FRB

        if type(ns.db.iconFileID) ~= "number" then
            ns.db.iconFileID = defaults.iconFileID
        end

        dataObject.icon = ns.db.iconFileID
    elseif event == "PLAYER_LOGIN" then
        if not ns.db then
            FRB = CopyDefaults(defaults, FRB or {})
            ns.db = FRB
        end

        LibDBIcon:Register("FastRenown", dataObject, ns.db.minimap)

        if ns.db.minimap.hide then
            LibDBIcon:Hide("FastRenown")
        else
            LibDBIcon:Show("FastRenown")
        end

        local btn = LibDBIcon:GetMinimapButton("FastRenown")
        if btn then
            btn:SetScale(1.0)
        end
    end
end)
