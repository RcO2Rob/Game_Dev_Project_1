# Underwater World

## Game idea

Underwater World is a short 2D platform game made in Godot. The player controls a small underwater robot trying to reach and restart an old machine inside a deep-sea temple. The game should take about 8-10 minutes to finish.

The movement is inspired by underwater levels in platform games, but I want to avoid making it feel slow. The player naturally sinks a little, taps the swim button to move upward, and can dive quickly when needed.

## Controls

- A/D or Left/Right: move
- Space: swim upward
- Down + Space: fast dive
- Escape: pause

The player can defeat a hermit crab by landing on it. Its empty shell can then be kicked into a breakable coral wall.

## Main rules

- The player slowly sinks when the swim button is not pressed.
- Repeated swim taps move the player upward.
- A fast dive cancels upward movement and sends the player down.
- Enemies and spikes cause damage.
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

## Development notes

I will build the movement first and adjust it through playtesting. The main goal is to make the underwater movement responsive instead of slow or slippery. After the movement feels good, I will add the reusable enemies and obstacles, then build the three stages.

## Changes between versions

| Version | Change | Reason |
| --- | --- | --- |
| Design v1 | Chose three stages and the swim/dive movement | Keep the project small enough to finish and polish |
