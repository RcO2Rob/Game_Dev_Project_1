# Underwater World

## Game idea

Underwater World is a short 2D platform game made in Godot. The player controls a small underwater robot trying to reach and restart an old machine inside a deep-sea temple. The game should take about 8-10 minutes to finish.

The movement is inspired by underwater levels in platform games, but I want to avoid making it feel slow. The player naturally sinks a little, taps the swim button to move upward, and can dive quickly when needed.

## Controls

- A/D: move
- W: swim upward
- S: fast dive
- N: pick up or throw a nearby rock
- Escape: pause

The player can carry and throw small rocks found on the seabed. The same interaction can later be reused for empty crab shells.

## Main rules

- The player slowly sinks when the swim button is not pressed.
- Repeated swim taps move the player upward.
- The player has three health points and can chain up to three swim jumps before landing.
- A fast dive cancels upward movement and sends the player down.
- Enemies and spikes cause damage.
- Thrown rocks defeat crabs, jellyfish, and sea urchins.
- Crabs can be defeated by stomping from above.
- Small jellyfish drift through the water and cannot be stomped.
- Sea urchins cannot be stomped and reset the player on contact.
- Gaps in the seabed immediately reset the player if they fall inside.
- Bubble vents use broad random intervals with occasional long pauses. A bubble traps the player, carries them upward, and then resets them.
- Bubbles can also capture thrown rocks and enemies. A captured object rises with the bubble, and the occupied bubble becomes a temporary moving platform the player can stand on.
- Coins are placed along the main route and increase the HUD coin counter when collected.
- Rare diamonds are placed on harder optional routes and have a separate HUD counter.
- The player begins and respawns at the doorway of a half-visible pineapple house on the far left.
- Crabs physically collide with loose rocks instead of walking through them.
- Enemy contact removes one health point without moving the player back to the start. Reaching zero health restarts from the spawn point.
- Falling into a seabed gap or being carried away by a bubble is an instant death.
- Entering the large conch shell at the far right transitions to Stage 2.
- Soft underwater music loops across stages. Rock hits, stomps, and player damage each have a distinct sound effect.
- Coins and rare diamonds have distinct pickup sounds. The player has idle/swim, fin, tilt, and blink animation, while seaweed sways and small ambient bubbles rise through each level.
- The stone sword is not collected automatically. When it is within reach, pressing N equips it and reveals it on the player. Pressing M performs a short animated sword swing that can defeat enemies.
- Wooden barrels ignore thrown rocks and can only be broken by the equipped sword. A broken barrel releases seven collectible coins.
- Barrel coins raycast toward the terrain and remain uncollectible while falling; they become collectible only after landing on the floor or platform below the barrel.
- The sword and a carried rock are mutually exclusive: equipping the sword drops any held rock and prevents further rock pickup. Sword swings can also pop empty or object-carrying bubbles.
- Pressing N while the sword is equipped throws it a short distance in front of the player. The dropped sword is a physical object affected by underwater gravity, falls onto terrain, and can be collected again with N.
- Losing all health returns the player to the latest checkpoint.
- Currents push the player in a visible direction.
- Reaching the exit finishes the first two stages. Escaping the temple finishes the game.

## Stage 1: Shallow Steps

This is the tutorial level and should take about 2.5 minutes. It has bright water, rocks, sea grass, and one checkpoint in the middle.

The level teaches movement, swim taps, and fast diving. The player also learns how to land on hermit crabs, kick a shell, push a floating log, and move through a gentle current. The end of the stage combines these actions in one short section.

## Stage 2: Surge Reef

This level should take about 3.5 minutes. It uses darker purple and green coral and has two checkpoints.

The main challenge is timing. Thermal vents turn on and off, pufferfish move through narrow paths, and currents push the player toward sea urchins. The player must reuse the movement learned in Stage 1 and kick a crab shell into a coral wall to open the exit.

## Stage 3: Temple Escape

This level should take about 3 minutes. The player starts the ancient machine, which causes the temple to collapse. The camera then begins moving to the right.

The escape combines currents, falling rocks, jellyfish, narrow passages, swim taps, and fast dives. There is one checkpoint halfway through. The camera should create pressure, but it should not move so quickly that one small mistake ends the run.

## Art and sound

The robot needs simple idle, walking, swimming, diving, hurt, and victory animations. Important actions such as swimming, taking damage, kicking a shell, touching a checkpoint, and completing a stage should have sound effects.

Terrain uses a strict 256x256 atlas divided into an 8x8 grid of 32x32 cells. Seam-safe sand, rock, ruin, and hole-edge tiles are kept separate from irregular decorations.

Coral and seaweed are reusable transparent decoration scenes. They have no collision and are kept outside the terrain TileSet so they can be positioned and scaled without affecting gameplay.

## Development notes

I will build the movement first and adjust it through playtesting. The main goal is to make the underwater movement responsive instead of slow or slippery. After the movement feels good, I will add the reusable enemies and obstacles, then build the three stages.

## Changes between versions

| Version | Change | Reason |
| --- | --- | --- |
| Design v1 | Chose three stages and the swim/dive movement | Keep the project small enough to finish and polish |
| Prototype v1 | Added the first grey-box movement room | Test movement before building enemies and levels |
| Polish v2 | Added character motion, seaweed sway, ambient bubbles, and event audio | Meet the graduate animation/audio requirements and make the underwater space feel alive |
