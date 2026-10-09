![BeastBond](docs/art/banner.png)

**Your hunter pet is more than a combat tool. It's a companion that depends on you.**
BeastBond helps you look after it: it tells you when your friend is hungry or hurting, keeps a little status card with their mood and how close the two of you have become, and remembers every pet you have ever raised.

> ### Help me look after your pets
> BeastBond has been tested in the Forever beta client, and I'd love more Hunters to try it with their own companions and tell me how it feels. Anything you notice, good or bad, makes it better for everyone. The [5 minute checklist](docs/TESTING.md) shows what to try.

| Settings | Pet journal |
|---|---|
| ![Settings](docs/screenshots/settings.png) | ![Pet journal](docs/screenshots/journal.png) |

## Meet your companion
- **Companion card**: a small card with your pet's portrait, name, mood face and a bond bar that fills as you spend time together.
- **Bond levels**: *New friends*, *Buddies*, *Good friends*, *Inseparable* and finally *Soulbound*. You get a message when you reach the next one.
- **Caring alerts, by name**: "Rex is getting hungry." "Rex is very unhappy! Feed them before they run away." No more guessing.
- **One-click feeding**: a feed button appears when your pet isn't happy and you carry food they like. It looks like a normal action button, shows how much food you have, and steps aside during combat.
- **Never lose them**: reminders to Call Pet or Revive Pet, quiet while you're mounted or on a taxi.
- **Pet journal**: every pet you've had, with family, level, zone, how long you've been together and your bond.
- **Rare tame tracker**: an alert when you spot a rare creature you could tame.

Everything can be switched on or off. See the [manual](docs/MANUAL.md).

## Install
- **CurseForge**: install with the CurseForge app (search "BeastBond"), or download the zip from the project page.
- **Manual**: unzip so the folder is `Interface/AddOns/BeastBond/BeastBond.toc` inside your Forever client folder, then restart the game or type `/reload`.

Type `/bb` in game to open the settings.

## Commands
| Command | What it does |
|---|---|
| `/bb` | open settings |
| `/bb journal` | open the pet journal (`reset confirm` clears it) |
| `/bb module <name> on\|off` | enable/disable a module: Guardian, FeedButton, Tracker, Journal, PetCard |
| `/bb reset` | reset the feed button and companion card positions |
| `/bb test <state>` | see an alert, the card or the feed button without a pet (`/bb test` lists them) |
| `/bb about` | version and feedback links |
| `/bb debug` | print diagnostic info (attach it to bug reports) |

## Tested, and looking for more eyes
Checked in the Forever beta client: loading, settings, every command, and each alert, the card, the feed button, the tracker and the journal through the built-in `/bb test` simulations.

Where I'd love your help is confirming it with real pets in everyday play:
- the mood face and alerts match what your pet is really feeling
- the feed button feeds with the food you carry
- the "tamed" mark appears when you tame a new pet
- the rare tame alert shows up on real rare creatures

## Give feedback
- **Something broke or looks off?** [Open a bug report](../../issues/new/choose). Include the Lua error (BugSack, or `/console scriptErrors 1`) and the output of `/bb debug` with your pet out.
- **Works great?** Tell me too: [share a test report](../../issues/new/choose). It really helps.
- **Ideas?** Same place. What would make your pet feel more alive?

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## License
MIT
