# Gerald Blocks (working title, Godot 4)

A block puzzle roguelite for Android in the Five More Minutes look. Built from Prism Blocks: drag pieces onto an 8x8 board and clear full rows and columns, while the Bog Toad sleeps in his nest below the board.

## How a run works

| Part | Details |
|---|---|
| Toad | Pick a toad before the run. Each has a perk (more gold, more slots, an extra nap...). Most are unlocked by playing. |
| Run | 8 nights of 3 rounds. Clear night 8 to win, then keep going in endless if you like. |
| Round | A fresh board, a score target and a piece budget (18, 18, 22). Miss the target or run out of space and the run is over. |
| Rounds per night | Light snooze (base target), Deep sleep (1.3x), Hero raid (1.6x). Targets live in `scripts/core/run.gd`. |
| Hero raid | Heroes walk down toward the nest. Fill a row or column through one to squash him. Each type has a trick (bombers explode, healers armour, thieves steal pieces, mages freeze blocks). A hero reaching the nest costs a nap. |
| Boss raid | Every other night's raid has a boss: lots of armour and his own trick. Squash him for a free rare monster; reaching the goal gives bonus time to catch him. |
| Shop | Between rounds, for gold: monsters (jokers, up to Lv 3, some grow, some shiny), line totems (level up a kind of clear, no cap), snacks (one use), mystery sacks and charms. All in `scripts/core/jokers.gd`. |
| Naps | 3 per run. Lose them all and the toad wakes up (run over). Surviving a raid gives one back. |
| Saving | The run is saved at the start of each round; Continue restarts that round. |

Also on the menu: **Squash mode** (endless heroes, no goal), the **Collection** (every monster found, lifetime records) and the **Wardrobe** (hats). Unlocks and stats live in `scripts/core/meta.gd`.

## Open and run

1. Install **Godot 4.3** (standard version) and import `project.godot`.
2. Press **F5**. On a computer the mouse stands in for your finger.

## Project layout

```
scripts/
  core/run.gd           run state, targets, piece budgets, buying and selling, saving
  core/jokers.gd        monsters, totems, snacks, charms, sacks, shiny editions, shop rolls
  core/meta.gd          lifetime stats and unlocks: toads, hats, locked monsters
  game/game_view.gd     board, tray, drag-and-drop, heroes, effects
  game/game_screen.gd   HUD, round intro, round and run end dialogs
  ui/fmm_art.gd         Five More Minutes art ported from its main.gd: heroes, the Bog Toad, his nest
  ui/hero_art.gd        the strip under the board: nest, naps, speech bubble
  ui/block_art.gd       inked, cel-shaded blocks
  ui/monster_art.gd     the shop's monsters, snacks, totems and charms
  screens/main_menu.gd  Continue run / New run / Squash mode
  screens/run_shop.gd   the toad's shop
  screens/toad_pick.gd, wardrobe.gd, collection.gd
```

Prism Blocks' Classic, Adventure, Daily and Shop code is still in the project but not on the menu.

## Testing

- `godot --headless --path . res://tests/run_bot.tscn -- --runs=20` plays whole runs with a greedy bot (it shops too) and prints how far it gets. `--toad=rich` picks a toad, `--squash` plays Squash mode. Add `--calibrate` to play every round's full piece budget and see the scores reached (for tuning targets).
- `xvfb-run godot --path . --resolution 720x1280 res://tests/run_shots.tscn` saves screenshots to `build/shots/` and renders `icon.png`.
