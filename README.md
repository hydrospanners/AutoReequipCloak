# AutoReequipCloak

**Teleport with your guild cloak — arrive wearing your real one.**

AutoReequipCloak fixes the oldest gear accident in the game: you equip a
teleport cloak (Cloak of Coordination, Wrap of Unity, Shroud of Cooperation),
use it, and forget to swap back. Three dungeons later you notice you have been
playing with a decade-old teleport cloak on.

The addon solves it twice — an automation and a safety net behind it:

1. **Automatic swap-back** — the moment you arrive, your previous cloak is
   re-equipped.
2. **A gear tripwire** — if a weak item still slips into an instance with you,
   you get a warning popup before the first pull.

No configuration, no options panel, no libraries. Install it and forget it
exists.

## The rules — automatic swap-back

1. **Remember.** When you equip a recognized teleport cloak over a normal
   cloak, the replaced cloak is remembered. Swapping from one teleport cloak
   to another keeps the original cloak remembered.
2. **Restore.** On the next zone change or loading screen — normally your
   teleport landing — the remembered cloak is re-equipped into the back slot.
3. **Verify.** The addon confirms the swap actually happened before it
   forgets; if the equip could not happen yet, it simply retries at the next
   opportunity.

And it quietly stands down when acting would be wrong:

- **In combat** — nothing happens until combat ends; then it retries.
- **You already fixed it yourself** — if the back slot no longer holds a
  teleport cloak, the addon clears its memory and does nothing.
- **The cloak is gone** — if the remembered cloak is no longer in your bags
  (banked, sold, destroyed), it stands down instead of guessing.

## The rules — low item level warning

The addon records your personal bests as you play, per character: highest
average equipped item level, highest back-slot item level, and the highest
item level ever seen in each teleport-capable slot. Against that history,
three tripwires are checked when you enter a dungeon, raid, or scenario — and
re-checked after each combat inside:

| # | Condition | Typical accident it catches |
|---|-----------|-----------------------------|
| 1 | A recognized teleport item is equipped at **≤ 60 %** of that slot's best | Still wearing the teleport item on the first boss |
| 2 | Back slot at **≤ 60 %** of your best back item — teleport cloak or not | Leveling or transmog cloak left on |
| 3 | Average equipped item level at **≤ 95 %** of your best | Fishing set, missing pieces, forgotten swap |

Any tripwire shows a popup with your current vs. highest item level; case 1
also prints a chat warning. Warnings never fire in the open world and are
throttled to one per 5 minutes.

Because the tripwires compare against *your own recorded history*, a fresh
install has no baseline and stays silent until it has seen your real gear
once — no false positives on day one.

## Recognized teleport items

Swap-back covers the **back slot**. The other slots are watch-only: they feed
tripwire 1 so a forgotten teleport ring or tabard still gets flagged.

| Slot | Items |
|------|-------|
| Back | Cloak of Coordination, Shroud of Cooperation, Wrap of Unity (both factions) |
| Neck | Blessed Medallion of Karabor |
| Rings | Ring of the Kirin Tor |
| Feet | Ruby Slippers, Boots of the Bay |
| Tabard | Argent Crusader's Tabard, Baradin's Wardens Tabard, Hellscream's Reach Tabard |
| Trinkets | Time-Lost Artifact, Brassiest Knuckle |

The list is curated. Missing an equippable teleport item? [Open an
issue](../../issues).

## What it never does

- Never acts in combat.
- Never uses the teleport for you and never equips the teleport cloak for
  you — you decide when to port; the addon only puts your real cloak back.
- Never touches any slot other than back when equipping.
- No background scanning — it reacts to equipment and zone events and is idle
  otherwise.

## Honest limitations

- The pending swap-back lives in memory: if you log out or `/reload` between
  equipping the teleport cloak and arriving, the addon forgets — the warning
  tripwires are the safety net for exactly that case.
- Restore is back-slot only; other slots warn but do not auto-swap.
- Any zone change triggers the restore, not just teleports — equip the cloak
  and cross a zone border on foot, and your real cloak comes back (just
  re-equip the teleport cloak).

## Command

- `/arc status` (or `/arc debug`) — prints current vs. best item level for
  every tracked slot, and the reason for the last warning.

## Installation

- **CurseForge:** search for *AutoReequipCloak* in the CurseForge app.
- **Manual:** download the latest zip from [Releases](../../releases/latest)
  and extract the `AutoReequipCloak` folder into
  `World of Warcraft\_retail_\Interface\AddOns\`, then `/reload`.

Requires World of Warcraft Retail (Midnight, 12.x).

## Acknowledgements

Inspired by the original
[TeleportCloak](https://www.wowinterface.com/downloads/info26733-TeleportCloak.html)
addon. AutoReequipCloak is a separate, independent implementation focused on
automatic back-slot re-equip after zoning and item-level safety warnings — it
does not bundle or copy TeleportCloak code.

## License

MIT — see [LICENSE](LICENSE).
