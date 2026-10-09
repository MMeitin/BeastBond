# Help test BeastBond

Thanks for looking after your pets with BeastBond. You need a **Hunter** (level 10+ with a pet is ideal) in the Forever client. It takes about 5 minutes, and you can do it while you play.

## Setup
1. Install BeastBond and start the game.
2. Turn on error display: type `/console scriptErrors 1`.
3. Type `/reload`. If a red error box appears, [report it](../../../issues/new/choose) with the text of the error.

## Checklist
Tick what you tried. Note anything that looks or feels off.

| # | Try this | You should see |
|---|---|---|
| 1 | `/bb` | settings panel opens |
| 2 | `/bb debug` with your pet **out** | a few lines of numbers (happiness, loyalty, food types). **Copy these into your report.** |
| 3 | Summon your pet | the companion card appears with their portrait, mood face and bond bar |
| 4 | Let your pet get hungry | an alert with your pet's name, and the mood face on the card changes |
| 5 | Carry food your pet eats while it is not happy | the feed button appears; clicking it feeds the pet |
| 6 | Dismiss your pet, then leave combat | "Your companion is not with you" (not while mounted) |
| 7 | Target a rare creature you can tame | a "Rare tame nearby" alert, once |
| 8 | `/bb journal` | your pets listed with family, level, zone, time together and bond |
| 9 | Tame a new pet | the pet is added to the journal and marked tamed |
| 10 | Spend an hour with a pet | bond reaches "Buddies" with a message |

## Without a pet
You can still see everything with simulations. `/bb test` lists them, for example `/bb test unhappy`, `/bb test card`, `/bb test feed`, `/bb test tame`. Each one prints `as expected` or `UNEXPECTED`.

## Reporting
Use the [issue forms](../../../issues/new/choose). The most useful bits are:
- the Lua error text, if any
- the output of `/bb debug` (pet out)
- what you expected and what happened

Reports that everything worked are just as valuable.
