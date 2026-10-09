# Contributing

BeastBond is a small, free hobby project. The most useful thing you can do is **try it and tell me how it went**.

## Feedback and bug reports
- Use the [issue forms](../../issues/new/choose).
- For bugs, include the Lua error text (BugSack, or `/console scriptErrors 1`) and the output of `/bb debug` with your pet out.
- [docs/TESTING.md](docs/TESTING.md) is a 5 minute checklist of what to try.

## Code
The code is MIT licensed: fork it and change it freely. Pull requests are welcome too, but there is no guarantee of a quick answer. If you send one, keep it to a single change, test it in game and make sure `luacheck .` is clean.

## Running your own copy
1. Clone the repository.
2. Copy the addon into your client: run `./scripts/deploy.ps1 -Dest "<client>\Interface\AddOns\BeastBond"`. To avoid typing the path again, put it in a file named `scripts/.deploy-dest` (ignored by git) or set `$env:BEASTBOND_DEST`.
3. In game: `/console scriptErrors 1`, then `/reload`.
4. Check things without a pet using `/bb test` (it lists every simulation).

## Checks
- `luacheck .` (also runs on every push)
- `bash scripts/check-toc.sh` makes sure the `.toc` lists every Lua file (also runs on every push)

## Art
`python scripts/make_textures.py` regenerates the textures in `Media/` (needs Pillow); `python scripts/make_art.py` regenerates the banner and logo in `docs/art/`. The game only sees new texture files after a full restart.

## Build a release zip
`./scripts/package.ps1` writes `dist/BeastBond-<version>.zip` (version = newest heading in `CHANGELOG.md`).
