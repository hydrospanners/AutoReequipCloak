# AutoReequipCloak

Re-equips your previous cloak after zoning with a teleport cloak equipped.

## Installation

1. Go to the [Releases](../../releases/latest) page and download the latest `.zip`
2. Extract the **AutoReequipCloak** folder into your addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Log in to WoW or type `/reload` in-game

## Requirements

- World of Warcraft Retail (Midnight / 12.x+)

## Features

- Saves your previous cloak when you equip a known teleport cloak.
- Re-equips the saved cloak automatically after a zone change.
- Warns before entering instances if ilvl looks unusually low:
  - Average ilvl dropped more than 5% from your recorded best.
  - Cloak or any teleport-slot item is at or below 60% of its recorded best.
  - Shows a popup and chat message with current vs. highest ilvl.
- Tracks highest ilvl seen across all teleport-capable slots (back, neck, ring, feet, tabard, trinket).
- Re-equip is back-slot only. Safety checks cover all tracked slots.

## Usage

- `/arc status` or `/arc debug` — prints current and highest ilvl per slot.
- See [TELEPORT_ITEMS.md](TELEPORT_ITEMS.md) for the list of recognised teleport item IDs.

## Acknowledgements

Inspired by the original [TeleportCloak](https://www.wowinterface.com/downloads/info26733-TeleportCloak.html) addon (also on [CurseForge](https://www.curseforge.com/wow/addons/teleportcloak)). AutoReequipCloak is a separate, independent implementation: it focuses on automatic back-slot re-equip after zoning and item-level safety warnings. It does not bundle or copy TeleportCloak code. The teleport item ID list draws on the same public game data and community references noted in [TELEPORT_ITEMS.md](TELEPORT_ITEMS.md).

## License

MIT — see [LICENSE](LICENSE).
