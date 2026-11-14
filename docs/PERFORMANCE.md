# Performance

Enemy load benchmark (SVTLW-90). Run it with:

```
godot --headless --path game -s res://tests/bench_enemies.gd
```

It spawns 100, 250, 500 and 1000 enemies through `EnemyManager`, cycling the five enemy types, and times 600 calls to `on_tick` at each size. Times are per simulation tick, not per frame.

## Measured (headless)

Machine: Windows 10 Home 10.0.19045, Godot 4.7.2 stable, console build, headless. CPU, RAM and GPU were not recorded, and the run had no rendering.

```
enemy tick benchmark, 600 ticks per size, headless
enemies  avg_tick_ms  max_tick_ms  objects  static_mem_mb
    100        0.1164       0.2650     1598          24.87
    250        0.3052       0.6900     1748          25.61
    500        0.6133       1.7720     1998          26.95
   1000        1.1701       2.2620     2498          29.34
```

What these numbers show:
- Tick cost grows about linearly with enemy count, roughly 1.2 ms per tick at 1000 enemies.
- The simulation runs at 10 ticks per second at 1x speed (`SimulationClock.TICKS_PER_SECOND`). At 1000 enemies that is about 12 ms of enemy logic per real second at 1x, and about 35 ms per second at 3x. This is derived from the tick cost, not a frame rate measurement.
- The object count rises by exactly the number of enemies (+150, +250, +500), so spawned enemies are freed and nothing leaks between sizes.
- Static memory grows by about 4.5 MB for 1000 enemies. This includes the Godot runtime, so the per-enemy cost is smaller than that.

Not measured: frame rate, rendering cost, projectile and effect cost during a fight, and GPU use. No frame rate is claimed here. Those need a run on real hardware with the battlefield scene.

## Hot path changes (SVTLW-90)

- `EnemyManager.on_tick` no longer copies the enemy array with `duplicate()` on every tick. It walks the live array by index and stops if a signal handler removed enemies mid-tick. The copy was the only per-tick allocation found in the enemy path by reading the code. No allocation profiler was run, so "no per-frame allocations" is not proven for the whole battlefield.

## Minimum hardware target (proposal)

Proposal only, to confirm on real hardware before it is written into a release:

- CPU: 4 cores, 64-bit, about 2.5 GHz (2015-era laptop class).
- RAM: 8 GB.
- GPU: integrated graphics with Vulkan or D3D12 support.
- Frame target: 60 fps at 1000 enemies on that machine, to be measured with the battlefield scene.

The headless numbers above suggest enemy logic is far below the frame budget on any modern CPU, but rendering is not measured, so this target is not yet confirmed.
