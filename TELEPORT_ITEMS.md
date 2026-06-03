# Teleport items — item IDs and sources

Yes, **we need item IDs**. The addon checks `GetInventoryItemID("player", slot)` against a set of known teleport item IDs to decide when to save “previous item” and when to re-equip after a zone change.

---

## Where to find item IDs

| Source | What it gives | URL / how to use |
|--------|----------------|-------------------|
| **Wowpedia** | Category of teleportation items (90+ pages); many with item IDs in the infobox. | [Category:Teleportation_items](https://wowpedia.fandom.com/wiki/Category:Teleportation_items) — open each item page for ID. |
| **Wowhead** | Search “teleport” in Items; each item page shows ID in URL and in the page. | [Items named "teleport"](https://www.wowhead.com/items/name:teleport) — filter by type (armor, etc.) and open item for ID. |
| **WoWDB** | Item pages include numeric ID (e.g. `/items/32757-blessed-medallion-of-karabor` → ID 32757). | [WoWDB Items](https://www.wowdb.com/items) — search and use ID from URL or page. |
| **TeleportCloak addon** | Curated list of equippable teleport items the addon supports; WoWInterface page lists names + Wowhead links (IDs in URLs). | [TeleportCloak – WoWInterface](https://www.wowinterface.com/downloads/info26733-TeleportCloak.html) (see “Supported Items”). |
| **In-game** | Any item: hold Shift and click the item, then paste the link in chat; the link contains the item ID (e.g. `item:32757:...`). | `/dump GetInventoryItemLink("player", slot)` or link in chat and parse. |

You can maintain a single table in the addon: `TELEPORT_ITEM_IDS[id] = true` (and optionally `TELEPORT_ITEM_IDS[id] = slotId` if you want per-slot lists). Add new IDs from Wowpedia/Wowhead/WoWDB or from in-game links.

### Practical "master list" workflow for Retail

There is no single official Blizzard-maintained exhaustive list for addon use. The most reliable workflow is:

1. Start from the broad category list: **Wowpedia/Warcraft Wiki teleportation items**.
2. Verify each candidate on **Wowhead** (item page + current Retail availability).
3. Keep a **curated equippable subset** (like TeleportCloak-supported items) for addon runtime logic.

---

## Consolidated list: equippable teleport items by slot

Below is a **single list of item IDs** you can use as the default “teleport items” set. It includes back (cloak), neck, ring, feet, tabard, and trinket. The addon can be implemented cloak-only first, then extended to other slots using the same IDs and the appropriate `INVSLOT_*` for each.

**Slot constants (Retail):** `INVSLOT_BACK` (15), `INVSLOT_NECK` (2), `INVSLOT_FINGER1` (11), `INVSLOT_FINGER2` (12), `INVSLOT_FEET` (8), `INVSLOT_BODY` (4, tabard), `INVSLOT_TRINKET1` (13), `INVSLOT_TRINKET2` (14).

### Back (cloak)

| Item | Item ID |
|------|---------|
| Cloak of Coordination | 65274, 65360 |
| Shroud of Cooperation | 63352 |
| Wrap of Unity | 63206 |

### Neck

| Item | Item ID | Notes |
|------|---------|--------|
| Blessed Medallion of Karabor | 32757 | Burning Crusade (Black Temple); teleport to Black Temple. |

### Ring

| Item | Item ID |
|------|---------|
| Ring of the Kirin Tor | 44935 |

### Feet

| Item | Item ID |
|------|---------|
| Ruby Slippers | 28585 |
| Boots of the Bay | 50287 |

### Tabard (body slot)

| Item | Item ID |
|------|---------|
| Argent Crusader's Tabard | 46874 |
| Baradin's Wardens Tabard | 63379 |
| Hellscream's Reach Tabard | 63378 |

### Trinket

| Item | Item ID |
|------|---------|
| Time-Lost Artifact | 103678 |
| Brassiest Knuckle | 95051 |

### Other (insignia / held items — may not be “equippable” in same way)

| Item | Item ID | Slot / notes |
|------|---------|--------------|
| Frostwolf Insignia | 17690 | Often held/use item. |
| Stormpike Insignia | 17691 | Often held/use item. |

---

## Flat list for addon default table

Use this as the default “any slot” set (addon can later restrict by slot if desired):

```lua
-- Equippable teleport items (all slots). Sources: Wowpedia, Wowhead, TeleportCloak addon.
-- Key = item ID, value = true (or slot id if you want per-slot lists).
local TELEPORT_ITEM_IDS = {
    -- Back
    [65274] = true, [65360] = true, [63352] = true, [63206] = true,
    -- Neck
    [32757] = true,  -- Blessed Medallion of Karabor (BC)
    -- Ring
    [44935] = true,
    -- Feet
    [28585] = true, [50287] = true,
    -- Tabard
    [46874] = true, [63379] = true, [63378] = true,
    -- Trinket
    [103678] = true, [95051] = true,
}
```

If you support multiple slots, you can store “previous item” per slot (e.g. `savedPreviousBySlot[INVSLOT_BACK]`, `savedPreviousBySlot[INVSLOT_NECK]`) and on zone change re-equip for each slot where the current equipped item is in `TELEPORT_ITEM_IDS` and you have a saved previous for that slot.
