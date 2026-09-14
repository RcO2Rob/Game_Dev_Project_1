# BUB-7: Temple Escape

Working title for CSCI 5499B/5999B Project 1.

## One-sentence pitch

Guide a small underwater repair robot through three compact side-scrolling stages by chaining buoyant swim taps, quick dives, currents, and enemy shells, then escape a collapsing deep-sea temple.

## Scope and learning goal

- Engine: Godot 4.7.2
- Format: 2D side-scrolling action platformer
- Theme: Underwater
- Target playtime: 8-10 minutes for a successful first playthrough
- Levels: three
- Primary learning goal: learn the movement set in Stage 1, apply it under timing pressure in Stage 2, and demonstrate mastery in Stage 3
- Scope rule: polish three movement actions and reuse a small set of hazards instead of adding unrelated mechanics

## Player fantasy and background

The player controls BUB-7, a compact maintenance robot sent to restart an ancient tidal engine. Activating the engine destabilizes the surrounding temple, turning the final stage into an escape. The character can walk on the seabed, propel upward through the water, and dive with enough force to attack enemies or activate mechanisms.

## Controls

| Action | Keyboard | Controller |
| --- | --- | --- |
| Move | Left/Right or A/D | Left stick/D-pad |
| Swim pulse | Space | South face button |
| Fast dive/pound | Down + Space | Down + south face button |
| Pause | Escape | Start/Menu |

Stomping, pushing floating logs, and kicking empty crab shells are contextual interactions and do not add more buttons.

## Movement model

Use `CharacterBody2D`, not physics-driven `RigidBody2D`, so movement remains deterministic and easy to tune.

Initial tuning values are starting points, not final promises:

| Parameter | Initial value/range | Design intent |
| --- | ---: | --- |
| Maximum horizontal speed | 210 px/s | Responsive without outrunning the camera |
| Seabed acceleration | 1200 px/s^2 | Quick ground response |
| Water acceleration | 600 px/s^2 | Softer underwater response |
| Seabed deceleration | 1600 px/s^2 | Crisp stop on the ground |
| Water deceleration | 350-500 px/s^2 | Brief controllable glide |
| Downward gravity | 340 px/s^2 | Gentle natural sinking |
| Maximum rise speed | 230 px/s | Prevent uncontrolled ascent |
| Maximum fall speed | 300 px/s | Keep hazards readable |
| Swim pulse | 175-195 px/s velocity change | Strong but chainable tap |
| Dive speed | 360 px/s | Immediate emergency descent |
| Input buffer | 0.10 s | Forgive slightly early presses |

The final values will be chosen through playtesting. A successful feel should allow precise correction after a swim tap, retain a small amount of momentum when input is released, and never make the player wait for the character to respond.

## Godot implementation map

| Gameplay element | Godot 4.7 implementation |
| --- | --- |
| Player controller | `CharacterBody2D` with `CollisionShape2D` and `CapsuleShape2D` |
| Movement loop | Update `velocity` inside `_physics_process()` and call `move_and_slide()` |
| Reusable gameplay object | A reusable `.tscn` scene rather than a Unity-style prefab |
| Rock and hazard tiles | `TileMapLayer` with terrain sets and collision layers |
| Current trigger | `Area2D` with `CollisionShape2D`; apply directional velocity while the player overlaps |
| Camera follow | `Camera2D` with position smoothing, drag margins, and stage limits |
| Particles | `GPUParticles2D` for bubbles, impacts, and current direction |

Water drag will be implemented explicitly with acceleration and deceleration values instead of relying on `RigidBody2D.linear_damp`. This makes the controller easier to reproduce and tune across all three stages.

## Core rules

1. BUB-7 naturally sinks unless the player uses swim pulses.
2. Repeated swim taps can gain height, but the rise speed is capped.
3. Down + Swim immediately cancels upward velocity and begins a fast dive.
4. Landing on a hermit crab with a dive defeats it and leaves a kickable shell.
5. Touching an active enemy or sharp hazard removes one health point and applies brief invulnerability.
6. Falling outside the stage or losing all health returns the player to the latest checkpoint.
7. Empty shells move horizontally when touched from the side and can break marked coral walls.
8. Current zones continuously influence movement; the same visual language is used in every stage.
9. Reaching the exit completes Stages 1 and 2. Surviving the escape completes Stage 3 and the game.

## Level progression

### Stage 1: Shallow Steps

- Target time: about 2.5 minutes
- Palette: bright blue water, sunlight rays, green sea grass
- Purpose: safely teach every player action and reusable interaction
- Checkpoints: one at approximately 50 percent

Sequence:

1. A safe lane teaches left/right movement and the character's slight water inertia.
2. Stone steps teach single and repeated swim pulses.
3. A ceiling urchin teaches Down + Swim as an emergency dive.
4. Two hermit crabs teach normal stomping and dive attacks.
5. A defeated crab leaves a shell; the player kicks it through a clearly marked brittle coral wall.
6. A floating log teaches contextual pushing.
7. A gentle current strip introduces the current visual effect before it becomes dangerous.
8. A short final room combines swim, dive, current, and shell use without severe punishment.

No required player ability is introduced after this stage.

### Stage 2: Surge Reef

- Target time: about 3.5 minutes
- Palette: fluorescent purple and green coral, narrow passages
- Purpose: apply Stage 1 skills through timing and combinations
- Checkpoints: two, placed before the two dense vent sections

Sequence:

1. Intermittent upward thermal vents require the player to read a clear warning animation and dive through the gap between eruptions.
2. Pufferfish follow an S-shaped patrol and block narrow passages; the player can swim around them or dive beneath them.
3. A current pushes the player toward ceiling urchins, requiring horizontal correction plus quick dives.
4. The player stomps a hermit crab, then uses its shell to open a coral barrier while avoiding the returning shell.
5. The final room combines a thermal vent, current, and moving enemy but provides a visible safe waiting pocket.

### Stage 3: Temple Escape

- Target time: about 3 minutes
- Palette: dark navy ruins with red warning lights and bright current lanes
- Purpose: demonstrate mastery under controlled pressure
- Checkpoints: one halfway through the escape

Sequence:

1. BUB-7 activates the tidal engine and the camera begins moving right at a constant, readable speed.
2. Familiar current zones become acceleration lanes rather than entirely new mechanics.
3. Falling debris uses the same warning language as the Stage 2 thermal vents.
4. Dashing jellyfish cross the route, with visible anticipation before each attack.
5. The route alternates between upward swim chains and fast dive passages.
6. The final stretch combines current assistance, shell breaking, and a closing exit without increasing the scroll speed unexpectedly.

The camera should pressure the player without instantly killing them for touching the left edge. Use a short grace zone and reset to the latest checkpoint after failure.

## Enemy and obstacle set

Keep the reusable set small:

- Hermit crab: horizontal patrol, stompable, produces a shell
- Pufferfish: S-shaped movement, avoided rather than defeated
- Jellyfish: telegraphed straight-line dash in Stage 3
- Sea urchin: static contact hazard
- Thermal vent: timed vertical hazard
- Current zone: constant directional force
- Brittle coral: breakable only by a moving shell
- Floating log: pushable environmental object

## Feedback and game feel

- Swim pulse: tail bubbles, short squash/stretch, soft propulsion sound
- Dive: fast pose change, stronger trail, impact particles on landing
- Enemy stomp: bounce, hit pause of approximately 0.05 s, shell pop-out
- Damage: brief flash, knockback, short invulnerability, distinct sound
- Current: particles and moving plants indicate direction before entry
- Thermal vent and jellyfish: anticipation animation and sound before danger
- Checkpoint: color change, chime, and persistent activation state
- Stage completion: short pose and clear transition rather than an abrupt scene switch

## Animation and audio coverage

Required character animations:

- idle/hover
- seabed walk
- swim pulse
- fast dive
- hurt
- victory

Required audio events:

- swim pulse
- dive impact
- enemy stomp
- shell kick and coral break
- player damage
- checkpoint activation
- thermal vent warning
- temple activation
- stage clear and game clear

## Design schemas

### Rules

The formal system consists of capped swim impulses, gentle sinking, fast dives, current forces, contextual shell interactions, health, checkpoints, hazards, and stage exit conditions.

### Play

The rules create rhythm: rise through repeated taps, correct momentum horizontally, then dive to recover position or exploit an opening. Later stages create mastery by combining familiar rules under stronger timing pressure rather than adding more controls.

### Culture

The underwater setting affects movement, animation, sound, visibility, enemies, and environmental forces. BUB-7's repair mission frames the ruins as a functional tidal machine instead of using underwater art as decoration alone.

## Three-day prototype target

### Day 1: movement and feel

- Create the Godot project and input actions
- Implement `CharacterBody2D` movement, swim pulse, dive, camera, and debug room
- Tune movement until a grey-box room feels responsive

### Day 2: reusable gameplay pieces

- Build TileMapLayer terrain and hazards
- Add checkpoints, current zones, hermit crab, shell, and brittle coral
- Grey-box all three stages

### Day 3: complete playable loop

- Add pufferfish, thermal vents, autoscroll, death/restart, menus, and ending
- Add minimum animations and audio feedback
- Run a timed playtest and record changes in the iteration log

## Iteration log

| Version/date | Playtest observation | Change | Reason |
| --- | --- | --- | --- |
| Design v1 | Initial scope locked | Chose three movement actions, three stages, and a reusable hazard set | Keep the project achievable while satisfying teaching progression |
