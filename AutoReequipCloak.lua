local INVSLOT_BACK_CONST = INVSLOT_BACK or 15
local INVSLOT_NECK_CONST = INVSLOT_NECK or 2
local INVSLOT_FEET_CONST = INVSLOT_FEET or 8
local INVSLOT_BODY_CONST = INVSLOT_BODY or 4
local INVSLOT_FINGER1_CONST = INVSLOT_FINGER1 or 11
local INVSLOT_FINGER2_CONST = INVSLOT_FINGER2 or 12
local INVSLOT_TRINKET1_CONST = INVSLOT_TRINKET1 or 13
local INVSLOT_TRINKET2_CONST = INVSLOT_TRINKET2 or 14
local LOW_ILVL_RATIO = 0.95
local LOW_CLOAK_ILVL_RATIO = 0.6
local LOW_TELEPORT_SLOT_ILVL_RATIO = 0.6
local LOW_ILVL_WARNING_COOLDOWN_SECONDS = 300
local LOW_ILVL_WARNING_POPUP_KEY = "AUTOREEQUIPCLOAK_LOW_ILVL_WARNING"

local TELEPORT_ITEM_IDS_BY_SLOT = {
    [INVSLOT_BACK_CONST] = {
        [65274] = true, -- Cloak of Coordination
        [65360] = true, -- Cloak of Coordination (Guild Perk variant)
        [63352] = true, -- Shroud of Cooperation
        [63206] = true, -- Wrap of Unity
    },
    [INVSLOT_NECK_CONST] = {
        [32757] = true, -- Blessed Medallion of Karabor
    },
    [INVSLOT_FINGER1_CONST] = {
        [44935] = true, -- Ring of the Kirin Tor
    },
    [INVSLOT_FINGER2_CONST] = {
        [44935] = true, -- Ring of the Kirin Tor
    },
    [INVSLOT_FEET_CONST] = {
        [28585] = true, -- Ruby Slippers
        [50287] = true, -- Boots of the Bay
    },
    [INVSLOT_BODY_CONST] = {
        [46874] = true, -- Argent Crusader's Tabard
        [63379] = true, -- Baradin's Wardens Tabard
        [63378] = true, -- Hellscream's Reach Tabard
    },
    [INVSLOT_TRINKET1_CONST] = {
        [103678] = true, -- Time-Lost Artifact
        [95051] = true, -- Brassiest Knuckle
    },
    [INVSLOT_TRINKET2_CONST] = {
        [103678] = true, -- Time-Lost Artifact
        [95051] = true, -- Brassiest Knuckle
    },
}

local frame = CreateFrame("Frame")

local lastBackItemID = nil
local savedPreviousCloakID = nil
local lowIlvlWarnedAt = 0
local pendingSafetyTimer = nil
local lastWarningReason = "none"

local db = nil

StaticPopupDialogs[LOW_ILVL_WARNING_POPUP_KEY] = {
    text = "Check your gear - your item level is unusually low.\nCurrent: %s\nHighest seen: %s",
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = STATICPOPUP_NUMDIALOGS,
}

local function GetEquippedBackItemID()
    return GetInventoryItemID("player", INVSLOT_BACK_CONST)
end

local function GetCurrentEquippedItemLevel()
    if GetAverageItemLevel then
        local _, equippedItemLevel = GetAverageItemLevel()
        if equippedItemLevel and equippedItemLevel > 0 then
            return equippedItemLevel
        end
    end

    return nil
end

local function GetItemLevelForSlot(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    if not itemLink then
        return nil
    end

    local itemLevel = GetDetailedItemLevelInfo(itemLink)
    if itemLevel and itemLevel > 0 then
        return itemLevel
    end

    return nil
end

local function GetEquippedBackItemLevel()
    return GetItemLevelForSlot(INVSLOT_BACK_CONST)
end

local function EnsureDB()
    AutoReequipCloakDB = AutoReequipCloakDB or {}
    AutoReequipCloakDB.highestEquippedItemLevel = tonumber(AutoReequipCloakDB.highestEquippedItemLevel) or 0
    AutoReequipCloakDB.highestBackSlotItemLevel = tonumber(AutoReequipCloakDB.highestBackSlotItemLevel) or 0
    AutoReequipCloakDB.highestTrackedSlotItemLevels = AutoReequipCloakDB.highestTrackedSlotItemLevels or {}
    db = AutoReequipCloakDB
end

local function UpdateHighestEquippedItemLevel()
    if not db then
        return
    end

    local equippedItemLevel = GetCurrentEquippedItemLevel()
    if not equippedItemLevel then
        return
    end

    if equippedItemLevel > db.highestEquippedItemLevel then
        db.highestEquippedItemLevel = equippedItemLevel
    end
end

local function UpdateHighestBackSlotItemLevel()
    if not db then
        return
    end

    local backItemLevel = GetEquippedBackItemLevel()
    if not backItemLevel then
        return
    end

    if backItemLevel > db.highestBackSlotItemLevel then
        db.highestBackSlotItemLevel = backItemLevel
    end
end

local function IsTeleportItemInSlot(slotID, itemID)
    local idsForSlot = TELEPORT_ITEM_IDS_BY_SLOT[slotID]
    return idsForSlot and itemID and idsForSlot[itemID] == true
end

local function UpdateHighestTrackedSlotItemLevels()
    if not db then
        return
    end

    for slotID, _ in pairs(TELEPORT_ITEM_IDS_BY_SLOT) do
        local currentItemLevel = GetItemLevelForSlot(slotID)
        if currentItemLevel and currentItemLevel > 0 then
            local previousBest = tonumber(db.highestTrackedSlotItemLevels[slotID]) or 0
            if currentItemLevel > previousBest then
                db.highestTrackedSlotItemLevels[slotID] = currentItemLevel
            end
        end
    end
end

local function IsDungeonOrRaidLikeInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return false
    end

    return instanceType == "party" or instanceType == "raid" or instanceType == "scenario"
end

local function WarnIfItemLevelIsUnusuallyLow()
    if not db or db.highestEquippedItemLevel <= 0 then
        return
    end

    if not IsDungeonOrRaidLikeInstance() then
        return
    end

    local equippedItemLevel = GetCurrentEquippedItemLevel()
    if not equippedItemLevel then
        return
    end

    local currentBackItemLevel = GetEquippedBackItemLevel()
    local highestBackItemLevel = db.highestBackSlotItemLevel or 0
    local isBackItemLevelSuspiciouslyLow = false
    if currentBackItemLevel and highestBackItemLevel > 0 then
        isBackItemLevelSuspiciouslyLow = currentBackItemLevel <= (highestBackItemLevel * LOW_CLOAK_ILVL_RATIO)
    end

    local lowTeleportSlots = {}
    for slotID, _ in pairs(TELEPORT_ITEM_IDS_BY_SLOT) do
        local equippedItemID = GetInventoryItemID("player", slotID)
        if IsTeleportItemInSlot(slotID, equippedItemID) then
            local currentSlotItemLevel = GetItemLevelForSlot(slotID)
            local highestSlotItemLevel = tonumber(db.highestTrackedSlotItemLevels and db.highestTrackedSlotItemLevels[slotID]) or 0
            if currentSlotItemLevel and highestSlotItemLevel > 0 then
                if currentSlotItemLevel <= (highestSlotItemLevel * LOW_TELEPORT_SLOT_ILVL_RATIO) then
                    lowTeleportSlots[#lowTeleportSlots + 1] = slotID
                end
            end
        end
    end

    local hasLowTeleportSlot = #lowTeleportSlots > 0
    local isAverageItemLevelLow = equippedItemLevel <= (db.highestEquippedItemLevel * LOW_ILVL_RATIO)
    if not hasLowTeleportSlot and not isBackItemLevelSuspiciouslyLow and not isAverageItemLevelLow then
        lastWarningReason = "none"
        return
    end

    local now = time()
    if lowIlvlWarnedAt > 0 and (now - lowIlvlWarnedAt) < LOW_ILVL_WARNING_COOLDOWN_SECONDS then
        return
    end

    lowIlvlWarnedAt = now
    if hasLowTeleportSlot then
        lastWarningReason = "low_teleport_slot"
    elseif isBackItemLevelSuspiciouslyLow then
        lastWarningReason = "low_back_slot"
    else
        lastWarningReason = "low_average_ilvl"
    end

    if hasLowTeleportSlot and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff7f00AutoReequipCloak:|r Teleport slot item level looks unusually low. Check gear before starting."
        )
    end
    StaticPopup_Show(
        LOW_ILVL_WARNING_POPUP_KEY,
        string.format("%.1f", equippedItemLevel),
        string.format("%.1f", db.highestEquippedItemLevel)
    )
end

local function GetSlotName(slotID)
    local names = {
        [INVSLOT_BACK_CONST] = "Back",
        [INVSLOT_NECK_CONST] = "Neck",
        [INVSLOT_FINGER1_CONST] = "Finger1",
        [INVSLOT_FINGER2_CONST] = "Finger2",
        [INVSLOT_FEET_CONST] = "Feet",
        [INVSLOT_BODY_CONST] = "Tabard",
        [INVSLOT_TRINKET1_CONST] = "Trinket1",
        [INVSLOT_TRINKET2_CONST] = "Trinket2",
    }
    return names[slotID] or tostring(slotID)
end

local function PrintDebugStatus()
    EnsureDB()
    local currentAvg = GetCurrentEquippedItemLevel() or 0
    local currentBack = GetEquippedBackItemLevel() or 0
    local highestAvg = db.highestEquippedItemLevel or 0
    local highestBack = db.highestBackSlotItemLevel or 0

    print(string.format("AutoReequipCloak: avg=%.1f highestAvg=%.1f back=%.1f highestBack=%.1f reason=%s",
        currentAvg, highestAvg, currentBack, highestBack, lastWarningReason))

    if db.highestTrackedSlotItemLevels then
        for slotID, _ in pairs(TELEPORT_ITEM_IDS_BY_SLOT) do
            local currentSlot = GetItemLevelForSlot(slotID) or 0
            local highestSlot = tonumber(db.highestTrackedSlotItemLevels[slotID]) or 0
            print(string.format("  %s ilvl=%.1f highest=%.1f", GetSlotName(slotID), currentSlot, highestSlot))
        end
    end
end

local function IsTeleportCloak(itemID)
    return IsTeleportItemInSlot(INVSLOT_BACK_CONST, itemID)
end

local function GetItemIDFromLink(link)
    if not link then
        return nil
    end

    local itemID = link:match("item:(%d+)")
    return itemID and tonumber(itemID) or nil
end

local function FindBagItemLinkByID(targetItemID)
    if not targetItemID then
        return nil
    end

    for bag = 0, 5 do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if GetItemIDFromLink(link) == targetItemID then
                return link
            end
        end
    end

    return nil
end

local function TryReequipSavedCloak()
    if not savedPreviousCloakID then
        return false
    end

    if UnitAffectingCombat("player") then
        return false
    end

    local currentlyEquipped = GetEquippedBackItemID()
    if not IsTeleportCloak(currentlyEquipped) then
        -- Current slot is no longer a tracked teleport cloak; clear stale state.
        savedPreviousCloakID = nil
        return false
    end

    local previousCloakLink = FindBagItemLinkByID(savedPreviousCloakID)
    if not previousCloakLink then
        savedPreviousCloakID = nil
        return false
    end

    EquipItemByName(previousCloakLink, INVSLOT_BACK_CONST)

    if GetEquippedBackItemID() == savedPreviousCloakID then
        savedPreviousCloakID = nil
        lastBackItemID = GetEquippedBackItemID()
        UpdateHighestEquippedItemLevel()
        UpdateHighestTrackedSlotItemLevels()
        return true
    end

    return false
end

local function OnPlayerEquipmentChanged(slotID)
    if slotID ~= INVSLOT_BACK_CONST then
        return
    end

    local currentBackID = GetEquippedBackItemID()
    if IsTeleportCloak(currentBackID) and lastBackItemID and not IsTeleportCloak(lastBackItemID) then
        savedPreviousCloakID = lastBackItemID
    end

    lastBackItemID = currentBackID
    UpdateHighestEquippedItemLevel()
    UpdateHighestBackSlotItemLevel()
    UpdateHighestTrackedSlotItemLevels()
end

local function OnPlayerLogin()
    EnsureDB()
    lastBackItemID = GetEquippedBackItemID()
    UpdateHighestEquippedItemLevel()
    UpdateHighestBackSlotItemLevel()
    UpdateHighestTrackedSlotItemLevels()

    SLASH_AUTOREEQUIPCLOAK1 = "/arc"
    SlashCmdList.AUTOREEQUIPCLOAK = function(msg)
        msg = (msg and msg:lower() or "")
        if msg == "debug" or msg == "status" then
            PrintDebugStatus()
            return
        end
        print("AutoReequipCloak commands: /arc debug, /arc status")
    end
end

local function RunSafetyChecks()
    TryReequipSavedCloak()
    UpdateHighestEquippedItemLevel()
    UpdateHighestBackSlotItemLevel()
    UpdateHighestTrackedSlotItemLevels()
    WarnIfItemLevelIsUnusuallyLow()
end

local function ScheduleSafetyChecks()
    if pendingSafetyTimer and pendingSafetyTimer.Cancel then
        pendingSafetyTimer:Cancel()
    end
    pendingSafetyTimer = C_Timer.NewTimer(0.3, function()
        pendingSafetyTimer = nil
        RunSafetyChecks()
    end)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        OnPlayerLogin()
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        OnPlayerEquipmentChanged(arg1)
        return
    end

    if event == "PLAYER_AVG_ITEM_LEVEL_UPDATE" then
        UpdateHighestEquippedItemLevel()
        UpdateHighestBackSlotItemLevel()
        UpdateHighestTrackedSlotItemLevels()
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
        ScheduleSafetyChecks()
    end
end)
