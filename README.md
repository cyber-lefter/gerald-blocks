# Gerald Blocks (working title, Godot 4)

A block puzzle roguelite for Android in the Five More Minutes look. Built from Prism Blocks: drag pieces onto an 8x8 board and clear full rows and columns, while the Bog Toad sleeps in his nest below the board.

## How a run works

| Part | Details |
|---|---|
| Run | 8 nights of 3 rounds. Clear night 8 to win. |
| Round | A fresh board, a score target and a piece budget (15, 15, 18). Miss the target or run out of space and the run is over. |
| Rounds per night | Light snooze (base target), Deep sleep (1.3x), Hero raid (1.5x). Targets live in `scripts/core/run.gd`. |
| Hero raid | Heroes enter at the top and step down after every piece. Fill a row or column through one to squash him (bonus points). Rogues move 2 steps, tanks take 2 hits, paladins 3. A hero reaching the nest costs a nap. |
| Naps | 3 per run. Lose them all and the toad wakes up (run over). Surviving a raid gives one back. |
| Saving | The run is saved at the start of each round; Continue restarts that round. |

Coming next: a shop between rounds with monster jokers that bend the scoring rules.

## Open and run

1. Install **Godot 4.3** (standard version) and import `project.godot`.
2. Press **F5**. On a computer the mouse stands in for your finger.

## Project layout

```
scripts/
  core/run.gd           run state, targets, piece budgets, saving
  game/game_view.gd     board, tray, drag-and-drop, heroes, effects
  game/game_screen.gd   HUD, round intro, round and run end dialogs
  ui/fmm_art.gd         Five More Minutes art ported from its main.gd: heroes, the Bog Toad, his nest
  ui/hero_art.gd        the strip under the board: nest, naps, speech bubble
  ui/block_art.gd       inked, cel-shaded blocks
  screens/main_menu.gd  New run / Continue run
```

Prism Blocks' Classic, Adventure, Daily and Shop code is still in the project but not on the menu.

## Testing

- `godot --headless --path . res://tests/run_bot.tscn -- --runs=20` plays whole runs with a greedy bot and prints how far it gets. Add `--calibrate` to play every round's full piece budget and see the scores reached (for tuning targets).
- `xvfb-run godot --path . --resolution 720x1280 res://tests/run_shots.tscn` saves screenshots to `build/shots/` and renders `icon.png`.
