# Auto Reequip Cloak (Private)

**Status:** Implemented (Retail 12.0.5, cloak-only runtime).

When you equip a teleport item (cloak, neck, ring, etc.), use it to teleport (e.g. to Orgrimmar), the addon automatically re-equips the **previous** item you had in that slot.

Inspired by the original **TeleportCloak** addon (e.g. [WoWInterface](https://www.wowinterface.com/downloads/info26733-TeleportCloak.html), [CurseForge](https://www.curseforge.com/wow/addons/teleportcloak)). This addon is currently implemented as **cloak-only** (back slot), with room to expand to other teleport-item slots later. **Item IDs are required** — see **TELEPORT_ITEMS.md** for sources and a default list.

Runtime files:

- `AutoReequipCloak.toc`
- `AutoReequipCloak.lua`

Safety behavior:

- Tracks the highest equipped average item level seen (`AutoReequipCloakDB.highestEquippedItemLevel`).
- Tracks the highest equipped back-slot item level seen (`AutoReequipCloakDB.highestBackSlotItemLevel`).
- Tracks highest item level seen for teleport-capable slots (`AutoReequipCloakDB.highestTrackedSlotItemLevels`).
- While entering dungeon/raid-like instances, warns if an equipped teleport item in any tracked slot is unusually low versus that slot's recorded best (primary signal).
- Keeps a dedicated cloak check plus the average-ilvl check (`95%`) as fallback signals.
- Shows an on-screen popup: **"Check your gear - your item level is unusually low."**
- Uses a 5% drop threshold to allow normal spec/gear variation without over-warning.

Debug commands:

- `/arc status` — prints current/highest average ilvl, cloak ilvl, per-slot tracked ilvls, and last warning reason.
- `/arc debug` — same output as status (alias).

---

## 1. Intended behavior

| Step | What happens |
|------|----------------|
| 1 | You are wearing your normal cloak (e.g. raid cloak). |
| 2 | You equip a teleport cloak in the back slot (manually or via macro). |
| 3 | You use the teleport cloak (click / macro) and teleport (e.g. to Orgrimmar). |
| 4 | **Addon:** After the zone change, it detects that the back slot still has a “teleport cloak” and that a “previous cloak” was stored. It then re-equips that previous cloak. |

So: **save previous cloak when a teleport cloak is equipped → on zone change, if back slot is a teleport cloak and we have a saved cloak, re-equip the saved cloak.**

---

## 2. Teleport items and item IDs

We need **item IDs** so the addon can tell "this equipped item is a teleport item" and when to save/restore the previous item. There is no in-game "is teleport" flag; we use a table of known IDs.

- **Full list and where to find IDs:** See **TELEPORT_ITEMS.md**. It lists online sources (Wowpedia, Wowhead, WoWDB, TeleportCloak addon, in-game) and a **default table** of equippable teleport items by slot: back (cloak), neck (e.g. Blessed Medallion of Karabor 32757 from Burning Crusade), ring, feet, tabard, trinket, with item IDs.
- Runtime re-equip is currently **cloak-only** (back slot), but safety checks now evaluate all tracked teleport-capable slots.

---

## 3. Overlap with other addons

- **NaowhQOL:** No “reequip cloak” or “teleport cloak” feature found in the codebase. No conflict.
- **Leatrix Plus:** No teleport-cloak or reequip-cloak feature. No conflict.
- **Original TeleportCloak:** If the user still has it installed, both could run; this addon is cloak-only and can be a lighter alternative or replacement for the cloak part.

---

## 4. Technical summary

- **Slot:** Back = `INVSLOT_BACK` (15). Use this constant; do not rely on raw 15/16 without checking docs.
- **Events:**
  - **PLAYER_EQUIPMENT_CHANGED** (slotId) — when slot 15 (back) changes, update “last back item” and, if the new item is a teleport cloak, save “previous cloak” = last back item.
  - **ZONE_CHANGED_NEW_AREA** (or equivalent zone-change event) — when entering a new zone, if back slot is a teleport cloak and we have a saved previous cloak, re-equip the saved cloak (from bags) and clear the saved state.
- **APIs:** `GetInventoryItemLink("player", INVSLOT_BACK)`, `GetInventoryItemID("player", INVSLOT_BACK)`, and a way to equip an item from bags (e.g. find item in bags by link/ID, then `EquipItemByName` or `C_Item` / item location). See DESIGN.md for details.
- **State:** Store `savedPreviousCloak` (link or item ID + location) when equipping a teleport cloak; clear after re-equipping or when it no longer applies.

See **DESIGN.md** for event flow, edge cases, and implementation notes.

---

## Known limits

- Runtime re-equip is still **cloak-only**.
- Safety checks for low item level are **multi-slot** (back, neck, ring, feet, tabard, trinket).
- Item-level APIs can briefly lag after zoning; the addon debounces checks to reduce false duplicate warnings.
