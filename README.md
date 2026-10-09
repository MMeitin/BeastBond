![BeastBond](docs/art/banner.png)

**BeastBond is a hunter pet guardian for World of Warcraft: Forever.** It tells you when your pet is hungry, dead or missing, gives you a one-click feed button, spots rare tames, and keeps a journal of every pet you've had.

> ### Beta: testers wanted
> BeastBond was built against the Forever beta client and checked with simulated pet states, but **it has not been tested by many Hunters with real pets yet**. That is the point of this release.
> If you play a Hunter, please try it and tell me what works and what doesn't. See [How to help test](docs/TESTING.md). It takes about 5 minutes.

| Settings | Pet journal |
|---|---|
| ![Settings](docs/screenshots/settings.png) | ![Pet journal](docs/screenshots/journal.png) |

## What it does

| | |
|---|---|
| **Happiness alerts** | Warns when your pet gets hungry or unhappy, before it runs away. Repeats at most every 30 seconds. |
| **Feed button** | Appears when your pet isn't happy and you carry food it eats. One click feeds. Movable, lockable, hides during combat, looks like a normal action button. |
| **Missing / dead pet warnings** | Reminds you to Call Pet or Revive Pet. Stays quiet while you're mounted, on a taxi or dead. |
| **Rare tame tracker** | Alerts when you target, or a nameplate shows, a rare creature you can tame. Once per creature. |
| **Pet journal** | Per-character list of your pets with family, level, zone and time together. |

Everything can be turned on or off. See the [manual](docs/MANUAL.md) for details.

## Install
- **CurseForge**: install with the CurseForge app (search "BeastBond"), or download the zip from the project page.
- **Manual**: unzip so the folder is `Interface/AddOns/BeastBond/BeastBond.toc` inside your Forever client folder, then restart the game or type `/reload`.

Type `/bb` in game to open the settings.

## Commands
| Command | What it does |
|---|---|
| `/bb` | open settings |
| `/bb journal` | open the pet journal (`reset confirm` clears it) |
| `/bb module <name> on\|off` | enable/disable a module: Guardian, FeedButton, Tracker, Journal |
| `/bb reset` | reset the feed button position |
| `/bb test <state>` | simulate a pet state to check alerts without a pet (`/bb test` lists them) |
| `/bb about` | version and feedback links |
| `/bb debug` | print diagnostic info (attach it to bug reports) |

## What is and isn't verified
Honest status, so you know what to look for:

| Area | Status |
|---|---|
| Loads without errors, settings panel, slash commands | Verified in the Forever beta |
| Alerts, feed button, tracker and journal logic | Verified with `/bb test` simulations |
| Real happiness values from a live pet | **Untested**: the addon assumes 1 = unhappy, 2 = content, 3 = happy |
| `/cast Feed Pet` with real food | **Untested** |
| "Tamed" flag in the journal (needs the Tame Beast spell ID) | **Untested** |
| Rare tame detection on a real rare beast | **Untested** |

## Give feedback
- **Something broke or looks wrong?** [Open a bug report](../../issues/new/choose). Include the Lua error (BugSack, or `/console scriptErrors 1`) and the output of `/bb debug` with your pet out.
- **Works fine?** That helps too: [tell me](../../issues/new/choose) what you tried and that it worked.
- **Ideas and requests:** same place.

## Contributing
Pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License
MIT
