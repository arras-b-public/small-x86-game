# Small x86 Assembly Game, for an MSDOS environment

A small Breakout-style game written in 16-bit x86 assembly for MS-DOS. It runs in VGA mode 13h (320x200, 256 colors) and is meant to be assembled with Turbo Assembler and run in DOSBox.

The game logic is my own assembly code. The walls, bricks, score, and lives display come from a small pre-built helper library (`util_br.obj`) which is linked in at build time. The source code for that file
is not provided in this public repo. 

## Gameplay

- Move the paddle left and right to keep the ball in play.
- The ball bounces off the walls, the bricks, and the paddle.
- Where the ball lands on the paddle decides its direction: left section sends it up and left, middle section straight up, right section up and right.
- You start with 3 lives. Losing the ball resets the ball and paddle and costs one life, and the game ends at 0.
- Bricks are worth 1 point in the bottom two rows, 3 in the middle two, and 5 in the top two.

### Controls

| Key | Action |
|---|---|
| A / a | Move paddle left |
| D / d | Move paddle right |
| 1 | Power-up: wide paddle |
| 2 | Power-up: laser |
| Esc | Quit |

### Power-ups

A power-up becomes available once you have earned 50 points since the last one you used (or 50 points in total for the first). Only one can be used per 50 points.

- **Wide paddle (1):** the paddle doubles from 32 to 64 pixels for 500 frames, or until you lose a life.
- **Laser (2):** a one-pixel laser shoots straight up from the middle of the paddle and destroys the first brick it hits. It disappears when it hits a brick or the top wall, or when you lose a life.

## Build and run

Requires Turbo Assembler (TASM), TLINK, and DOSBox. You also need `util_br.obj` in the same folder

```
tasm bricks
tlink bricks util_br
bricks
```


## How it works

Each pass of the main loop runs in this order:

1. Sleep for 10 ms (from the helper library)
2. Erase the ball, move it by its velocity, and draw it at its new position
3. Check collisions: bricks, walls, then paddle, and update the ball velocity
4. Update the wide paddle timer and move the laser, if active
5. Add any newly earned points to the power-up balance
6. If the ball fell off the bottom, handle the lost life
7. Check the keyboard for movement, power-up, or quit keys

Some implementation notes:

- **Direct video memory.** Pixels are drawn by writing to segment `A000h` at offset `y * 320 + x`, and the same memory is read back to detect collisions.
- **Collisions by color.** The paddle's three sections are drawn in three different colors, and the paddle collision check just reads the pixel under the ball to see which section it is above. The helper library detects brick collisions the same way using the shaded edge colors of each brick.
- **Collision codes.** The wall and brick checks return 0 for no hit, 1 for a side, 2 for a top or bottom, and 3 for a corner, and the velocity is flipped accordingly.
- **Stack-based calling convention.** Routines take their arguments on the stack and clean them up with `ret N`, so the game code and the helper library use the same convention.