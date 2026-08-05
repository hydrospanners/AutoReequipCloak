local INVSLOT_HEAD_CONST = INVSLOT_HEAD or 1
local INVSLOT_NECK_CONST = INVSLOT_NECK or 2
local INVSLOT_SHOULDER_CONST = INVSLOT_SHOULDER or 3
local INVSLOT_CHEST_CONST = INVSLOT_CHEST or 5
local INVSLOT_WAIST_CONST = INVSLOT_WAIST or 6
local INVSLOT_LEGS_CONST = INVSLOT_LEGS or 7
local INVSLOT_FEET_CONST = INVSLOT_FEET or 8
local INVSLOT_WRIST_CONST = INVSLOT_WRIST or 9
local INVSLOT_HAND_CONST = INVSLOT_HAND or 10
local INVSLOT_FINGER1_CONST = INVSLOT_FINGER1 or 11
local INVSLOT_FINGER2_CONST = INVSLOT_FINGER2 or 12
local INVSLOT_TRINKET1_CONST = INVSLOT_TRINKET1 or 13
local INVSLOT_TRINKET2_CONST = INVSLOT_TRINKET2 or 14
local INVSLOT_BACK_CONST = INVSLOT_BACK or 15
local INVSLOT_MAINHAND_CONST = INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND_CONST = INVSLOT_OFFHAND or 17
local INVSLOT_TABARD_CONST = INVSLOT_TABARD or 19
local LOW_ILVL_RATIO = 0.95
local LOW_SLOT_ILVL_RATIO = 0.6
local LOW_ILVL_WARNING_COOLDOWN_SECONDS = 300
local LOW_ILVL_WARNING_POPUP_KEY = "AUTOREEQUIPCLOAK_LOW_ILVL_WARNING"
local REEQUIP_RETRY_INTERVAL_SECONDS = 0.5
local REEQUIP_RETRY_MAX_ATTEMPTS = 20

-- Equip locations that occupy both weapon slots, making an empty off-hand
-- legitimate (two-handers, bows, guns/crossbows/wands, fishing poles).
local TWO_HANDED_EQUIP_LOCS = {
    ["INVTYPE_2HWEAPON"] = true,
    ["INVTYPE_RANGED"] = true,
    ["INVTYPE_RANGEDRIGHT"] = true,
    ["INVTYPE_FISHINGPOLE"] = true,
}

-- Finger and trinket slots come in interchangeable pairs; a saved item found
-- worn on the paired slot means the player rearranged it deliberately.
local SIBLING_SLOT = {
    [INVSLOT_FINGER1_CONST] = INVSLOT_FINGER2_CONST,
    [INVSLOT_FINGER2_CONST] = INVSLOT_FINGER1_CONST,
    [INVSLOT_TRINKET1_CONST] = INVSLOT_TRINKET2_CONST,
    [INVSLOT_TRINKET2_CONST] = INVSLOT_TRINKET1_CONST,
}

-- All four Kirin Tor rings and their Inscribed/Etched/Runed upgrades teleport
-- to Dalaran (Northrend). One shared table, referenced by both finger slots.
local KIRIN_TOR_RING_IDS = {
    [40585] = true, -- Signet of the Kirin Tor
    [40586] = true, -- Band of the Kirin Tor
    [44934] = true, -- Loop of the Kirin Tor
    [44935] = true, -- Ring of the Kirin Tor
    [45688] = true, -- Inscribed Band of the Kirin Tor
    [45689] = true, -- Inscribed Loop of the Kirin Tor
    [45690] = true, -- Inscribed Ring of the Kirin Tor
    [45691] = true, -- Inscribed Signet of the Kirin Tor
    [48954] = true, -- Etched Band of the Kirin Tor
    [48955] = true, -- Etched Loop of the Kirin Tor
    [48956] = true, -- Etched Ring of the Kirin Tor
    [48957] = true, -- Etched Signet of the Kirin Tor
    [51557] = true, -- Runed Signet of the Kirin Tor
    [51558] = true, -- Runed Loop of the Kirin Tor
    [51559] = true, -- Runed Ring of the Kirin Tor
    [51560] = true, -- Runed Band of the Kirin Tor
}

local TELEPORT_ITEM_IDS_BY_SLOT = {
    [INVSLOT_BACK_CONST] = {
        [65274] = true, -- Cloak of Coordination (Horde)
        [65360] = true, -- Cloak of Coordination (Alliance)
        [63352] = true, -- Shroud of Cooperation (Alliance)
        [63353] = true, -- Shroud of Cooperation (Horde)
        [63206] = true, -- Wrap of Unity (Alliance)
        [63207] = true, -- Wrap of Unity (Horde)
    },
    [INVSLOT_NECK_CONST] = {
        [32757] = true, -- Blessed Medallion of Karabor
    },
    [INVSLOT_FINGER1_CONST] = KIRIN_TOR_RING_IDS,
    [INVSLOT_FINGER2_CONST] = KIRIN_TOR_RING_IDS,
    [INVSLOT_FEET_CONST] = {
        [28585] = true, -- Ruby Slippers
        [50287] = true, -- Boots of the Bay
    },
    [INVSLOT_TABARD_CONST] = {
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

-- Every gear slot the low-gear warning watches and records personal bests
-- for. Shirt and tabard are excluded from the generic below-your-best and
-- empty-slot checks (their item level is meaningless), but the tabard's best
-- is still tracked because the teleport-tabard tripwire compares against it.
-- Empty slots warn once a best is recorded for them; the off-hand is exempt
-- while the main hand holds a two-hand-type weapon.
local ILVL_TRACKED_SLOT_IDS = {
    INVSLOT_HEAD_CONST, INVSLOT_NECK_CONST, INVSLOT_SHOULDER_CONST,
    INVSLOT_CHEST_CONST, INVSLOT_WAIST_CONST, INVSLOT_LEGS_CONST,
    INVSLOT_FEET_CONST, INVSLOT_WRIST_CONST, INVSLOT_HAND_CONST,
    INVSLOT_FINGER1_CONST, INVSLOT_FINGER2_CONST,
    INVSLOT_TRINKET1_CONST, INVSLOT_TRINKET2_CONST,
    INVSLOT_BACK_CONST, INVSLOT_MAINHAND_CONST, INVSLOT_OFFHAND_CONST,
    INVSLOT_TABARD_CONST,
}

local ILVL_TRACKED_SLOT_SET = {}
for _, slotID in ipairs(ILVL_TRACKED_SLOT_IDS) do
    ILVL_TRACKED_SLOT_SET[slotID] = true
end

local frame = CreateFrame("Frame")

local lastItemIDBySlot = {}
local savedPreviousItemIDBySlot = {}
local lowIlvlWarnedAt = 0
local pendingSafetyTimer = nil
local lastWarningReason = "none"
local reequipTicker = nil
local reequipAttemptsLeft = 0

local db = nil

StaticPopupDialogs[LOW_ILVL_WARNING_POPUP_KEY] = {
    text = "%s",
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

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

    local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
    if itemLevel and itemLevel > 0 then
        return itemLevel
    end

    return nil
end

local function EnsureDB()
    AutoReequipCloakDB = AutoReequipCloakDB or {}
    AutoReequipCloakDB.highestEquippedItemLevel = tonumber(AutoReequipCloakDB.highestEquippedItemLevel) or 0
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

local function IsTeleportItemInSlot(slotID, itemID)
    local idsForSlot = TELEPORT_ITEM_IDS_BY_SLOT[slotID]
    return idsForSlot and itemID and idsForSlot[itemID] == true
end

local function UpdateHighestTrackedSlotItemLevel(slotID)
    if not db or not ILVL_TRACKED_SLOT_SET[slotID] then
        return
    end

    local currentItemLevel = GetItemLevelForSlot(slotID)
    if currentItemLevel and currentItemLevel > 0 then
        local previousBest = tonumber(db.highestTrackedSlotItemLevels[slotID]) or 0
        if currentItemLevel > previousBest then
            db.highestTrackedSlotItemLevels[slotID] = currentItemLevel
        end
    end
end

local function UpdateHighestTrackedSlotItemLevels()
    for _, slotID in ipairs(ILVL_TRACKED_SLOT_IDS) do
        UpdateHighestTrackedSlotItemLevel(slotID)
    end
end

local function IsDungeonOrRaidLikeInstance()
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        return false
    end

    return instanceType == "party" or instanceType == "raid" or instanceType == "scenario"
end

local function GetSlotName(slotID)
    local names = {
        [INVSLOT_HEAD_CONST] = "Head",
        [INVSLOT_NECK_CONST] = "Neck",
        [INVSLOT_SHOULDER_CONST] = "Shoulder",
        [INVSLOT_CHEST_CONST] = "Chest",
        [INVSLOT_WAIST_CONST] = "Waist",
        [INVSLOT_LEGS_CONST] = "Legs",
        [INVSLOT_FEET_CONST] = "Feet",
        [INVSLOT_WRIST_CONST] = "Wrist",
        [INVSLOT_HAND_CONST] = "Hands",
        [INVSLOT_FINGER1_CONST] = "Finger1",
        [INVSLOT_FINGER2_CONST] = "Finger2",
        [INVSLOT_TRINKET1_CONST] = "Trinket1",
        [INVSLOT_TRINKET2_CONST] = "Trinket2",
        [INVSLOT_BACK_CONST] = "Back",
        [INVSLOT_MAINHAND_CONST] = "MainHand",
        [INVSLOT_OFFHAND_CONST] = "OffHand",
        [INVSLOT_TABARD_CONST] = "Tabard",
    }
    return names[slotID] or tostring(slotID)
end

local function DescribeSlotItem(slotID)
    return GetInventoryItemLink("player", slotID) or GetSlotName(slotID)
end

local function IsWieldingTwoHander()
    local mainHandLink = GetInventoryItemLink("player", INVSLOT_MAINHAND_CONST)
    if not mainHandLink then
        return false
    end

    local itemEquipLoc = select(9, C_Item.GetItemInfo(mainHandLink))
    if not itemEquipLoc then
        -- Item data not cached yet; assume the empty off-hand is fine rather
        -- than risk a false warning.
        return true
    end

    return TWO_HANDED_EQUIP_LOCS[itemEquipLoc] == true
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

    local lowTeleportLines = {}
    local lowSlotLines = {}
    local emptySlotNames = {}
    for _, slotID in ipairs(ILVL_TRACKED_SLOT_IDS) do
        local equippedItemID = GetInventoryItemID("player", slotID)
        local highestSlotItemLevel = tonumber(db.highestTrackedSlotItemLevels[slotID]) or 0
        if not equippedItemID then
            -- The 14 armor/accessory slots are never legitimately empty; the
            -- off-hand is, but only under a two-hand-type main weapon. Only
            -- flag slots we have a recorded best for, so a fresh install (or
            -- a character that never fills the slot) stays silent.
            if highestSlotItemLevel > 0 and slotID ~= INVSLOT_TABARD_CONST then
                local offHandUnderTwoHander = slotID == INVSLOT_OFFHAND_CONST and IsWieldingTwoHander()
                if not offHandUnderTwoHander then
                    emptySlotNames[#emptySlotNames + 1] = GetSlotName(slotID)
                end
            end
        else
            local currentSlotItemLevel = GetItemLevelForSlot(slotID)
            if currentSlotItemLevel and highestSlotItemLevel > 0
                and currentSlotItemLevel <= (highestSlotItemLevel * LOW_SLOT_ILVL_RATIO) then
                local line = string.format("%s (%d vs best %d)",
                    DescribeSlotItem(slotID), currentSlotItemLevel, highestSlotItemLevel)
                if IsTeleportItemInSlot(slotID, equippedItemID) then
                    lowTeleportLines[#lowTeleportLines + 1] = line
                elseif slotID ~= INVSLOT_TABARD_CONST then
                    lowSlotLines[#lowSlotLines + 1] = line
                end
            end
        end
    end

    local hasLowTeleportSlot = #lowTeleportLines > 0
    local hasEmptySlot = #emptySlotNames > 0
    local hasLowSlot = #lowSlotLines > 0
    local isAverageItemLevelLow = equippedItemLevel <= (db.highestEquippedItemLevel * LOW_ILVL_RATIO)
    if not hasLowTeleportSlot and not hasEmptySlot and not hasLowSlot and not isAverageItemLevelLow then
        lastWarningReason = "none"
        return
    end

    local now = time()
    if lowIlvlWarnedAt > 0 and (now - lowIlvlWarnedAt) < LOW_ILVL_WARNING_COOLDOWN_SECONDS then
        return
    end

    lowIlvlWarnedAt = now
    local detailParts = {}
    if hasLowTeleportSlot then
        detailParts[#detailParts + 1] = "Still wearing " .. table.concat(lowTeleportLines, ", ")
    end
    if hasEmptySlot then
        detailParts[#detailParts + 1] = "Empty: " .. table.concat(emptySlotNames, ", ")
    end
    if hasLowSlot then
        detailParts[#detailParts + 1] = "Way below your best: " .. table.concat(lowSlotLines, ", ")
    end
    if hasLowTeleportSlot then
        lastWarningReason = "low_teleport_slot"
    elseif hasEmptySlot then
        lastWarningReason = "empty_slot"
    elseif hasLowSlot then
        lastWarningReason = "low_slot"
    else
        lastWarningReason = "low_average_ilvl"
    end

    local detail = (#detailParts > 0) and table.concat(detailParts, ". ") or nil
    if detail and DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffff7f00AutoReequipCloak:|r " .. detail .. ". Check gear before starting."
        )
    end

    -- Lead with the low-average claim only when the average tripwire actually
    -- fired; per-slot triggers get a neutral lead so the headline never
    -- contradicts the healthy-looking averages shown below it.
    local popupBody
    if isAverageItemLevelLow then
        popupBody = string.format(
            "Check your gear. Your item level is unusually low.\nCurrent: %.1f  Highest seen: %.1f",
            equippedItemLevel, db.highestEquippedItemLevel)
        if detail then
            popupBody = popupBody .. "\n" .. detail
        end
    else
        popupBody = "Check your gear before starting."
        if detail then
            popupBody = popupBody .. "\n" .. detail
        end
        popupBody = popupBody .. string.format(
            "\nAverage: %.1f (best %.1f)", equippedItemLevel, db.highestEquippedItemLevel)
    end
    StaticPopup_Show(LOW_ILVL_WARNING_POPUP_KEY, popupBody)
end

local function FindBagItemLinkByID(targetItemID)
    if not targetItemID then
        return nil
    end

    for bag = 0, 5 do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            if C_Container.GetContainerItemID(bag, slot) == targetItemID then
                return C_Container.GetContainerItemLink(bag, slot)
            end
        end
    end

    return nil
end

local function StopReequipTicker()
    if reequipTicker then
        reequipTicker:Cancel()
        reequipTicker = nil
    end
end

-- One pass over every slot with a pending swap-back. Equips complete
-- asynchronously (the server confirms via PLAYER_EQUIPMENT_CHANGED), so this
-- never judges an equip request in the frame it was issued — a later pass or
-- the equipment event observes the result.
local function TryReequipSavedItems()
    if next(savedPreviousItemIDBySlot) == nil then
        StopReequipTicker()
        return "idle"
    end

    if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player") then
        return "blocked"
    end

    local anyPending = false
    local anyMissing = false
    for slotID, savedItemID in pairs(savedPreviousItemIDBySlot) do
        local currentItemID = GetInventoryItemID("player", slotID)
        if currentItemID == savedItemID then
            savedPreviousItemIDBySlot[slotID] = nil
            lastItemIDBySlot[slotID] = currentItemID
        elseif not IsTeleportItemInSlot(slotID, currentItemID) then
            -- The user equipped something else there on purpose; stop chasing.
            savedPreviousItemIDBySlot[slotID] = nil
        elseif SIBLING_SLOT[slotID] and GetInventoryItemID("player", SIBLING_SLOT[slotID]) == savedItemID then
            -- The saved ring/trinket is worn on the paired slot: the player
            -- rearranged it deliberately (this also stops a duplicate bag copy
            -- from being equipped over the teleport item they placed). Say so
            -- in one line — with two identical copies owned this can also be
            -- a real stand-down, and stand-downs are never silent.
            savedPreviousItemIDBySlot[slotID] = nil
            if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
                local siblingLink = GetInventoryItemLink("player", SIBLING_SLOT[slotID])
                DEFAULT_CHAT_FRAME:AddMessage(
                    "|cffff7f00AutoReequipCloak:|r " .. (siblingLink or "Your item") .. " is on your other slot. Leaving it there."
                )
            end
        else
            local savedItemLink = FindBagItemLinkByID(savedItemID)
            if savedItemLink then
                C_Item.EquipItemByName(savedItemLink, slotID)
                anyPending = true
            else
                -- Bag data can be empty right after a loading screen; keep the
                -- saved item — the retry ticker decides when to give up.
                anyMissing = true
            end
        end
    end

    if not anyPending and not anyMissing then
        StopReequipTicker()
        UpdateHighestEquippedItemLevel()
        UpdateHighestTrackedSlotItemLevels()
        return "done"
    end

    if anyMissing and not anyPending then
        return "missing"
    end

    return "attempted"
end

local function GiveUpReequip(itemsAreMissing)
    StopReequipTicker()
    if next(savedPreviousItemIDBySlot) == nil then
        return
    end

    wipe(savedPreviousItemIDBySlot)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        if itemsAreMissing then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffff7f00AutoReequipCloak:|r Couldn't find your previous gear in your bags. Swap it back manually."
            )
        else
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffff7f00AutoReequipCloak:|r Couldn't re-equip your previous gear in time. Swap it back manually."
            )
        end
    end
end

local function StartReequipRetries()
    if next(savedPreviousItemIDBySlot) == nil then
        return
    end

    reequipAttemptsLeft = REEQUIP_RETRY_MAX_ATTEMPTS
    if reequipTicker then
        return
    end

    reequipTicker = C_Timer.NewTicker(REEQUIP_RETRY_INTERVAL_SECONDS, function()
        local status = TryReequipSavedItems()
        if status == "blocked" then
            return -- in combat or dead: equips are impossible, don't burn attempts
        end

        reequipAttemptsLeft = reequipAttemptsLeft - 1
        if reequipAttemptsLeft <= 0 and reequipTicker then
            GiveUpReequip(status == "missing")
        end
    end)
end

local function PrintDebugStatus()
    EnsureDB()
    local currentAvg = GetCurrentEquippedItemLevel() or 0
    local highestAvg = db.highestEquippedItemLevel or 0

    print(string.format("AutoReequipCloak: avg=%.1f highestAvg=%.1f reason=%s",
        currentAvg, highestAvg, lastWarningReason))

    for _, slotID in ipairs(ILVL_TRACKED_SLOT_IDS) do
        local currentSlot = GetItemLevelForSlot(slotID) or 0
        local highestSlot = tonumber(db.highestTrackedSlotItemLevels[slotID]) or 0
        print(string.format("  %s ilvl=%.1f highest=%.1f", GetSlotName(slotID), currentSlot, highestSlot))
    end

    for slotID, savedItemID in pairs(savedPreviousItemIDBySlot) do
        local displayName = FindBagItemLinkByID(savedItemID)
            or (C_Item.GetItemNameByID and C_Item.GetItemNameByID(savedItemID))
            or ("item " .. savedItemID)
        print(string.format("  pending swap-back: %s -> %s", GetSlotName(slotID), displayName))
    end
end

local function OnPlayerEquipmentChanged(slotID)
    local isTeleportTrackedSlot = TELEPORT_ITEM_IDS_BY_SLOT[slotID] ~= nil
    if not isTeleportTrackedSlot and not ILVL_TRACKED_SLOT_SET[slotID] then
        return
    end

    if isTeleportTrackedSlot then
        local currentItemID = GetInventoryItemID("player", slotID)

        if savedPreviousItemIDBySlot[slotID] and currentItemID == savedPreviousItemIDBySlot[slotID] then
            -- The saved item is back on (equipped by us or by hand); done chasing it.
            savedPreviousItemIDBySlot[slotID] = nil
            if next(savedPreviousItemIDBySlot) == nil then
                StopReequipTicker()
            end
        elseif IsTeleportItemInSlot(slotID, currentItemID)
            and lastItemIDBySlot[slotID]
            and not IsTeleportItemInSlot(slotID, lastItemIDBySlot[slotID]) then
            savedPreviousItemIDBySlot[slotID] = lastItemIDBySlot[slotID]
        end

        lastItemIDBySlot[slotID] = currentItemID
    end

    UpdateHighestEquippedItemLevel()
    UpdateHighestTrackedSlotItemLevel(slotID)
end

local function OnPlayerLogin()
    EnsureDB()
    for slotID, _ in pairs(TELEPORT_ITEM_IDS_BY_SLOT) do
        lastItemIDBySlot[slotID] = GetInventoryItemID("player", slotID)
    end
    UpdateHighestEquippedItemLevel()
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
    UpdateHighestEquippedItemLevel()
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
frame:RegisterEvent("LOADING_SCREEN_DISABLED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
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
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED" then
        -- Arrival moments are the ONLY points that arm the swap-back, so a
        -- teleport item that is equipped but not yet used is never removed
        -- out from under the player.
        StartReequipRetries()
        if reequipTicker then
            TryReequipSavedItems()
        end
        ScheduleSafetyChecks()
        return
    end

    if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_REGEN_ENABLED" then
        -- Assist an already-armed swap-back (bags settled / combat ended);
        -- these must never arm it themselves.
        if reequipTicker then
            TryReequipSavedItems()
        end
        if event == "PLAYER_REGEN_ENABLED" then
            ScheduleSafetyChecks()
        end
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        ScheduleSafetyChecks()
    end
end)
