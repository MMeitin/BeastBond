# How to help test BeastBond

Thanks for trying it. You need a **Hunter** (level 10+ with a pet is ideal) in the Forever client. It takes about 5 minutes.

## Setup
1. Install BeastBond and start the game.
2. Turn on error display: type `/console scriptErrors 1`.
3. Type `/reload`. If a red error box appears, [report it](../../../issues/new/choose) with the text of the error.

## Checklist
Tick what you tried. Write down anything that looks wrong.

| # | Try this | You should see |
|---|---|---|
| 1 | `/bb` | settings panel opens |
| 2 | `/bb debug` with your pet **out** | a few lines of numbers (happiness, loyalty, food types). **Copy these into your report.** |
| 3 | Let your pet get hungry (or note its mood on the pet frame) | an alert text + sound when it becomes hungry / unhappy |
| 4 | Carry food your pet eats while it is not happy | a feed button appears; clicking it feeds the pet |
| 5 | Dismiss your pet, leave combat | a "No pet summoned" warning (not while mounted) |
| 6 | Target a rare creature you can tame | a "Rare tame nearby" alert, once |
| 7 | `/bb journal` | your pets listed with family, level, zone and time together |
| 8 | Tame a new pet | the pet is added to the journal and flagged as tamed |

## Without a pet
You can still check the basics with simulations: `/bb test` lists them, for example `/bb test unhappy`, `/bb test feed`, `/bb test tame`. Each one prints `as expected` or `UNEXPECTED`.

## Reporting
Use the [issue forms](../../../issues/new/choose). The most useful bits are:
- the Lua error text, if any
- the output of `/bb debug` (pet out)
- what you expected and what happened

Reports that everything worked are valuable too.
