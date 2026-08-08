# AutoReequipCloak

**Teleport with your guild cloak — arrive wearing your real one.**

AutoReequipCloak fixes the oldest gear accident in the game: you equip a
teleport cloak (Cloak of Coordination, Wrap of Unity, Shroud of Cooperation),
use it, and forget to swap back. Three dungeons later you notice you have been
playing with a decade-old teleport cloak on.

The addon solves it twice: an automatic swap-back, and a safety net behind it.

1. **Automatic swap-back.** The moment you arrive, your previous gear goes
   back on.
2. **A gear tripwire.** If a weak item still slips into an instance with you,
   you get a warning popup before the first pull.

No configuration, no options panel, no libraries. Install it and forget it
exists.

## The rules: automatic swap-back

1. **Remember.** When you equip a recognized teleport item over a normal
   item, the replaced item is remembered, per slot. Swapping from one
   teleport item to another keeps the original remembered. The memory is
   saved with your character: logging out or reloading before you arrive
   doesn't lose it.
2. **Restore.** When the teleport cast finishes, or at the latest when the
   loading screen ends, every remembered item is re-equipped into its own
   slot. A same-city teleport that just blinks you across with no loading
   screen counts too, and a disconnect mid-swap finishes on your next
   login. It retries for about ten seconds, so a slow loading screen or
   unsettled bag data can't make it miss.
3. **Verify.** The addon confirms the swap actually happened on your
   character before it forgets. If it can't finish in time, it tells you in
   chat instead of failing silently.

And it quietly stands down when acting would be wrong:

- **In combat or dead.** Retries pause until you're back. Arriving dead and
  running to your corpse doesn't burn the retry window.
- **You already fixed it yourself.** If the slot no longer holds a teleport
  item, or you moved the ring/trinket to its other slot on purpose, the addon
  clears its memory and does nothing.
- **The item is gone.** If the remembered item is no longer in your bags
  (banked, sold, destroyed), it says so once in chat and stands down instead
  of guessing.
- **It ran out of time.** If the equips wouldn't go through within about ten
  seconds, one chat line tells you to swap manually. Never silent.

## The rules: low item level warning

The addon records your personal bests as you play, per character: highest
average equipped item level, and the highest item level ever seen in every
gear slot, head to weapons. Against that history, four tripwires are checked
when you enter a dungeon, raid, or scenario, and re-checked after each combat
inside:

| # | Condition | Typical accident it catches |
|---|-----------|-----------------------------|
| 1 | A recognized teleport item is equipped at **≤ 60 %** of that slot's best | Still wearing the teleport item on the first boss |
| 2 | A gear slot is **empty** (off-hand exempt while wielding a two-hander, bows and guns included) | Unequipped something and forgot to put anything back |
| 3 | Any gear slot at **≤ 60 %** of that slot's own best | Fishing pole, leveling piece, transmog leftover |
| 4 | Average equipped item level at **≤ 95 %** of your best | Missing pieces, systematically wrong set |

Any tripwire shows a popup with your current vs. highest item level. Cases
1-3 also name the offending item or slot, with its item level against that
slot's best, in both the popup and a chat line. Warnings never fire in the
open world and are throttled to one per 5 minutes. Shirt is not tracked at
all, and the tabard only matters for the teleport check, since tabard item
level means nothing.

Because the tripwires compare against *your own recorded history*, a fresh
install has no baseline and stays silent until it has seen your real gear
once. No false positives on day one.

## Recognized teleport items

Swap-back covers every slot below; the same list feeds tripwire 1, so a
teleport item that somehow stays on still gets flagged at the door. Tabards
are the one exception: they carry no stats, so the door check has nothing to
measure and stays quiet for them. The once-per-item login notice covers
teleport tabards instead.

| Slot | Items |
|------|-------|
| Back | Cloak of Coordination, Shroud of Cooperation, Wrap of Unity (both factions) |
| Neck | Blessed Medallion of Karabor |
| Rings | All 16 Kirin Tor rings (Band, Loop, Ring, Signet and their upgrades) |
| Feet | Ruby Slippers, Boots of the Bay |
| Tabard | Argent Crusader's Tabard, Baradin's Wardens Tabard, Hellscream's Reach Tabard |
| Trinkets | Time-Lost Artifact, Brassiest Knuckle |

The list is curated. Missing an equippable teleport item? [Open an
issue](../../issues).

## What it never does

- Never acts in combat.
- Never uses the teleport for you and never equips the teleport item for
  you. You decide when to port; the addon only puts your real gear back.
- Only ever re-equips the exact item it saw replaced, into the same slot.
- No background scanning. It reacts to equipment and arrival events and is
  idle otherwise.

## Honest limitations

- The swap-back only knows items it saw replace something. Equipped over an
  empty slot, before the addon was installed, or while it was disabled,
  there is nothing to restore. The first login that notices says so in one
  chat line, once per item, and the warning tripwires stay as the safety
  net.
- Any loading screen triggers the restore, not just teleports. Equip a
  teleport item and then walk into a dungeon instead, and your real gear
  comes back. (Probably what you wanted anyway.)
- Items are matched by ID: if you carry a second copy of the replaced item at
  a different upgrade level, the swap-back may put on the other copy. And if
  an identical copy is worn on your other ring/trinket slot, the addon
  assumes you rearranged on purpose and leaves it, saying so in chat.

## Commands

- `/arc status` (or `/arc debug`) prints current vs. best item level for
  every tracked slot, and the reason for the last warning.
- `/arc log` prints the last 40 swap-back decisions (remember, restore,
  stand-down, give-up), timestamped. `/arc clearlog` empties it.

## Installation

- **CurseForge:** search for *AutoReequipCloak* in the CurseForge app.
- **Manual:** download the latest zip from [Releases](../../releases/latest)
  and extract the `AutoReequipCloak` folder into
  `World of Warcraft\_retail_\Interface\AddOns\`, then `/reload`.

Requires World of Warcraft Retail (Midnight, 12.x).

## Acknowledgements

Inspired by the original
[TeleportCloak](https://www.wowinterface.com/downloads/info26733-TeleportCloak.html)
addon. AutoReequipCloak is a separate, independent implementation of the same
idea. It does not bundle or copy TeleportCloak code.

## License

MIT, see [LICENSE](LICENSE).
