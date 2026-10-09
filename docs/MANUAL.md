# BeastBond manual

BeastBond is made of four modules. Each can be turned off with `/bb module <name> off`.

## Guardian
Watches your pet's mood and presence.
- **Hungry / unhappy alert**: shown when happiness drops. The same alert never repeats within 30 seconds.
- **Missing / dead pet**: after loading, leaving combat or summoning, you get "No pet summoned" or "Your pet is dead". Only for Hunters level 10+ who own a pet. Never while mounted, on a taxi, in combat or dead.
- Settings: "On-screen alerts", "Alert sound", "Missing pet alert".

## FeedButton
A one-click button that feeds your pet.
- Appears only when you are a Hunter with a pet, the pet is not happy, and you carry food it can eat.
- Shows the food icon and how many you have. Hover for the food name and the pet's mood.
- **Move it**: hold Shift and drag. **Lock it**: "Lock feed button" in settings. **Reset**: `/bb reset`.
- During combat it fades out, and returns afterwards.
- Setting: "Feed button".

## Tracker
Spots rare creatures you can tame.
- Looks at your target and at nameplates. A rare creature with a pet family triggers "Rare tame nearby: name (family, level)".
- One alert per creature. Hunters only. Silent inside instances.
- Setting: "Rare tame alert".

## Journal
A log of your pets, per character.
- Every pet is recorded the first time it is seen, with family, level, zone and date.
- "Time together" grows one minute per minute that the pet is out.
- A pet is marked **tamed** if you cast Tame Beast shortly before it appeared.
- Open with `/bb journal`. **Copy / export** shows the list as plain text you can select and copy.
- `/bb journal reset confirm` clears the current character's journal.

## Commands
| Command | What it does |
|---|---|
| `/bb` | settings |
| `/bb help` | list commands |
| `/bb journal` | open the journal |
| `/bb module <name> [on\|off]` | show or toggle a module |
| `/bb reset` | reset the feed button position |
| `/bb test <state>` | simulate: unhappy, content, happy, dead, missing, feed, tame, tamecommon, tamerepeat, tamed, tamedrepeat |
| `/bb about` | version and links |
| `/bb debug` | print diagnostic info; `debug on` / `debug off` toggles verbose messages |

## Troubleshooting
- **Nothing happens / no commands**: make sure the folder is `Interface/AddOns/BeastBond` and contains `BeastBond.toc`, then `/reload`.
- **A red error box**: copy its text into a bug report.
- **No feed button**: it only shows when your pet is not happy and you carry food it eats. Check with `/bb test feed`.
- **Too many alerts**: untick "On-screen alerts" or "Alert sound", or turn a module off.

## FAQ
**Does it work for other classes?** No, it is for Hunters.

**Does it change my pet or play for me?** No. It only alerts you. The feed button needs your click.

**Why "beta"?** It is verified with simulations but still needs testing with live pets. See [TESTING.md](TESTING.md).
