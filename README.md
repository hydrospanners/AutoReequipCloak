# AutoReequipCloak

Re-equips your previous cloak after zoning with a teleport cloak equipped.

## Features

- Saves your previous cloak when you equip a known teleport cloak.
- Re-equips the saved cloak automatically after a zone change.
- Warns before entering instances if ilvl looks unusually low:
  - Average ilvl dropped more than 5% from your recorded best.
  - Cloak or any teleport-slot item is at or below 60% of its recorded best.
  - Shows a popup and chat message with current vs. highest ilvl.
- Tracks highest ilvl seen across all teleport-capable slots (back, neck, ring, feet, tabard, trinket).
- Re-equip is back-slot only. Safety checks cover all tracked slots.
- `/arc status` or `/arc debug` — prints current and highest ilvl per slot.

## Install

Place the `AutoReequipCloak` folder in `Interface/AddOns/` and enable it in-game.
See `TELEPORT_ITEMS.md` for the full list of recognised teleport item IDs.
