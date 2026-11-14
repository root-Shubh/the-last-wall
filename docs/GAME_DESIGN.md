# Game Design

Status: M1 scope, SVTLW-22. Full design source is the master design brief. This document holds the parts the current milestone builds against.

## Identity

- **Title:** The Last Wall
- **Genre:** incremental defence, idle strategy, horde survival, fortress management
- **Tone:** dark medieval fantasy on the surface, science-fiction escape underneath
- **Platform:** Windows first, Steam later
- **Engine:** Godot 4.7, GDScript, 2D side view

## Premise

The player commands the last human fortress in a world overrun by hostile creatures. Through incremental progression they build a stronghold, recruit defenders, research technology and survive larger hordes. The world is a VR simulation. The goal is to survive Wave 1000 and defeat the Machine Overlords.

## Pillars

1. **Visible progression:** the fortress changes as the player advances.
2. **Satisfying combat:** large hordes are destroyed by growing defensive power.
3. **Meaningful upgrades:** upgrades unlock capabilities, not only bigger numbers.
4. **Strategic choice:** several builds are viable.
5. **Long-term play:** reasons to keep going for hours.
6. **Narrative in systems:** the simulation story changes gameplay and the ending.
7. **Low friction:** readable, responsive, easy to learn.

## Core loop

Prepare → recruit and upgrade → repair and build → allocate resources → start wave (manual or automatic) → automatic combat with optional abilities → rewards and stats → research → recover → next wave.

Game speed: pause (stops simulation, UI stays live), 1×, 2×, 3×.

## Milestone 1 scope (vertical slice)

- Main menu with Continue, New Game, Settings, Credits, Exit.
- Character selection: male or female avatar, customisable name, cosmetic only.
- Short opening narrative (friend, headset, SIMULATION ERROR notification).
- Battlefield: fortress left, enemy spawn right.
- One wall with health, damage states and repair.
- Archers with recruitment and population slots.
- Three enemy types: Undead Infantry, Runner, Armoured Brute.
- Automatic combat, enemy deaths, gold rewards.
- Basic wave progression with manual and automatic start.
- Five upgrades.
- Versioned save and load.

Anything outside this list waits for its milestone. See `docs/ROADMAP.md`.

## Player-facing rules for M1

- The wall fails at zero health. The defeat screen shows wave reached, kills and gold.
- Archers target the nearest enemy in range. Targeting modes arrive in M2.
- Recruiting costs gold and uses a population slot. A fallen archer frees the slot.
- Upgrades have a base cost, a cost multiplier, an effect, and a maximum level, all defined as data.
- Character choice has no gameplay effect.

## Out of scope for M1

Research, buildings, the other unit classes, the Horde Director, abilities, campaign regions, prestige, offline progression, instability and Steam integration.
