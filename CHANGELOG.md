# Changelog

## 1.3.1 - 2026-08-08

- A teleport without a loading screen never triggered the restore: using the
  cloak while already in its destination city is an instant blink, and the
  addon only listened for loading-screen arrivals. The finished teleport
  cast itself now arms the restore, so the swap lands either way.
- The remembered gear now survives logging out and `/reload`. Equip the
  teleport cloak, log off for the night, port the next morning, and the swap
  still happens. Before, any logout or reload between equipping and arriving
  silently emptied the addon's memory. This was the easiest way to end up
  "still wearing the cloak" with no error anywhere.
- Same protection after landing: if you disconnect or reload right as you
  arrive, before the swap finishes, it completes on your next login.
- Fixed two more silent ways the swap-back could die: an equip that passes
  through an empty slot no longer breaks the remembering, and a slot that
  reads as empty right after a loading screen is no longer mistaken for a
  deliberate gear change.
- Logging in wearing a teleport item the addon has no record for (equipped
  over an empty slot, before this version, or while the addon was off) now
  gets one chat line saying it won't be swapped back automatically, instead
  of silence after the teleport. Once per item, not every login.
- New: `/arc log` prints the addon's last 40 decisions: every remember,
  restore, stand-down and give-up, timestamped. If a swap ever misses again,
  the log says why. `/arc clearlog` empties it.

## 1.3.0 - 2026-08-06

- Fixed the big one: the swap-back after a teleport never actually worked, in
  any released version. The old code made a single equip attempt 0.3 seconds
  after arrival, while the loading screen was still up. The game drops equip
  requests there, and an empty bag read could wipe the remembered cloak on
  top of it. The addon now retries every half second for up to 10 seconds
  after the loading screen closes, and checks that the swap really happened
  before it stops.
- The swap-back now covers every tracked slot, not just the back slot.
  Teleport rings, boots, tabards, trinkets and the Karabor medallion all
  return your original item after landing.
- Plain zone changes no longer trigger the restore, only arrival after a
  loading screen. Crossing a zone border with a teleport item equipped but
  not used yet no longer swaps it away mid-plan.
- If the swap-back can't finish, the addon says so in chat. One line, whether
  the item left your bags or the equips just didn't go through in time.
- Retries pause while you're dead, so a corpse run doesn't eat the retry
  window. The swap lands after you resurrect.
- Moving a teleport ring or trinket between its two slots now counts as
  deliberate, instead of causing a bogus "gear missing" warning later.
- The low-gear warning now watches every gear slot: anything far below that
  slot's own best, and any slot that is empty. An empty off-hand is fine
  while you wield a two-hander, bows and guns included. Warnings name the
  actual item or slot in the popup and in chat.
- The addon got an icon in the AddOns list.
- Internals: current C_Item and C_Container namespaces everywhere, a dead
  pre-Midnight popup workaround removed, and equipment events now update
  only the slot that changed.

## 1.2.0 - 2026-07-27

- Now watches all 16 Kirin Tor rings (Band, Loop, Ring and Signet plus their
  Inscribed, Etched and Runed upgrades). Before this, only the base Ring of
  the Kirin Tor was recognized.

## 1.1.1 - 2026-07-22

- Marked compatible with 12.1 alongside 12.0.7. Support for 12.0.5 is
  dropped.

## 1.1.0 - 2026-07-21

- Fixed: tabard teleport items were watched on the shirt slot (4) instead of
  the tabard slot (19), so tabard warnings could never fire.
- Fixed: added the missing Horde variants of Shroud of Cooperation (63353)
  and Wrap of Unity (63207), and corrected the faction labels on the Cloak
  of Coordination item IDs.
- Updated Interface to 120007.
- Added CurseForge release packaging (BigWigs packager workflow plus
  `.pkgmeta`).
- Rewrote the README with the full rule set of both features.

## 1.0.0 - 2026-06-30

- Initial release: automatic cloak swap-back after teleporting with a guild
  teleport cloak, plus low item-level warnings when entering instances.
