# Art checklist (all characters 18+, clearly adult)

## Player (per style + body combo, e.g. `assets/player/egirl_curvy/`)
`state_0.png` fully dressed ... `state_4.png` all layers removed. 5 images per combo.
Styles: normal, egirl, emo, sporty, goth. Bodies: slim, athletic, curvy. Start with ONE combo.
Suggested size: 1024x1536, same pose/framing in all 5 (generate state_0 first, then inpaint the rest).

## Scenes (`assets/scenes/<id>/beat_0.png`, `beat_1.png`, ...)
Ids: office, restroom, storage, dungeon. Text for each beat goes in `data/scenes.json`.

## Enemies
`assets/enemies/<look>.png` (looks 1-5, see data/enemies.json). Mixed types/bodies, all adult.

Missing images are fine: the game shows placeholders until you add files.
Tip: `Hide explicit art` toggle in the menu shows only state_0.
