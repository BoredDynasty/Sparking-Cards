# SpringShaker

> A physics-based camera shaker for Roblox built on a damped harmonic oscillator — giving shakes real weight, momentum, and natural decay.

Traditional camera shakers scale Perlin noise by a fade envelope and call it a day. SpringShaker drives each shake through a damped harmonic oscillator — the same math that governs real pendulums and spring systems. Explosions ring out naturally, earthquakes swell and bleed off over time, and impacts feel physically grounded rather than scripted.

---

## Installation

**Roblox Marketplace** — [Get SpringShaker](https://create.roblox.com/store/asset/72358969628018/SpringShaker)

**GitHub** — [Latest Release](https://github.com/nilleniumrust/SpringShaker/releases)

**Wally:**
```toml
[dependencies]
SpringShaker = "nilleniumrust/springshaker@1.1.2"
```

> ⚠️ SpringShaker is **client-only**. Do not place it in server-side DataModel services.

---

## Usage

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpringShaker = require(ReplicatedStorage.src.SpringShaker)

-- Sustained earthquake until manually stopped
SpringShaker:ShakeSustained(SpringShaker:GetPreset("Earthquake"))

task.delay(5, function()
    SpringShaker:HaltDurationWise(1) -- smooth 1 second fade out
end)
```

Compare this to what other modules require — manual CFrame management, a secondary Heartbeat connection to fix drift, and writing your own render loop:

```lua
-- What you'd write with other modules
local camCf: CFrame
shake:BindToRenderStep(Shake.NextRenderName(), priority, function(pos, rot, isDone)
    camCf = camera.CFrame
    camera.CFrame *= CFrame.new(pos) * CFrame.Angles(rot.X, rot.Y, rot.Z)
end)
RunService.Heartbeat:Connect(function()
    camera.CFrame = camCf -- required to prevent drift at high FPS
end)
```

SpringShaker handles render priority, camera application, and drift prevention internally. Nothing to configure.

---

## Custom Shakes

```lua
local mortar = SpringShaker.new({
    Magnitude = 5,
    Roughness = 5,
    FadeInTime = 0,
    FadeOutTime = 1.8,
    Tension = 122,
    Damping = 13,
    RotationInfluence = Vector3.new(1.2, 0.5, 0.3),
})

SpringShaker:ShakeOnce(mortar)
```

| Parameter | Type | Description |
| --- | --- | --- |
| Magnitude | number | Scale of the entire shake. Acts as amplitude. |
| Roughness | number | Speed of the Perlin noise sampling. |
| FadeInTime | number | Seconds to reach full shake intensity. |
| FadeOutTime | number | Seconds to decay back to zero. |
| Tension | number | Oscillation frequency — higher values = faster wobble. |
| Damping | number | Resistance to oscillation — higher values = quicker ring-down. |
| RotationInfluence | Vector3 | Per-axis rotation multiplier (pitch, yaw, roll). |

> ⚠️ Do not set Magnitude above `10^5`. This risks [Resonance](https://en.wikipedia.org/wiki/Resonance) — SpringShaker will abort and warn if detected.

---

## Presets

| Preset | Description |
| --- | --- |
| Explosion | Violent initial shock that decays into heavy rumble |
| Landmine | Sharp high-tension sting that stabilizes almost instantly |
| Earthquake | Low-frequency rolling sway — ground liquefying feeling |
| Resonance | Slow rhythmic wobble that builds over time |
| Bounce | Soft fluid recoil with minimal roughness |
| Vibration | Subtle continuous hum |
| ExplosiveBullet | Fast sharp crack of a nearby hit |
| Rumble | Low persistent ground vibration |
| Impact | Sudden blunt force with quick ring-down |

---

## Performance

Benchmarked in Play mode with `os.clock()` wrapping only the update cost per frame — camera application excluded for fairness.

### SpringShaker native vs non-native

| Instances | Non-Native Avg | Non-Native Peak | Native Avg | Native Peak |
| --- | --- | --- | --- | --- |
| 1 | 0.0039ms | 0.0237ms | 0.004ms | 0.015ms |
| 10 | 0.0135ms | 0.0516ms | 0.013ms | 0.056ms |
| 50 | 0.0558ms | 0.2506ms | 0.056ms | 0.134ms |
| 100 | 0.1093ms | 0.1956ms | 0.110ms | 0.161ms |
| 250 | 0.2804ms | 0.6637ms | 0.282ms | 0.422ms |

`--!native` provides ~25x faster per-call performance and ~28% less peak memory at scale.

### Three-way comparison (all with `--!native`)

| Instances | SpringShaker | RbxCameraShaker | Shake |
| --- | --- | --- | --- |
| 1 | 0.0054ms | 0.0062ms | 0.0081ms |
| 10 | 0.0199ms | 0.0159ms | 0.0130ms |
| 50 | 0.0636ms | 0.0518ms | 0.0355ms |
| 100 | 0.1199ms | 0.1032ms | 0.0566ms |
| 250 | 0.2822ms | 0.2385ms | 0.1369ms |
| 1000 | ~1.20ms | ~0.88ms | ~0.51ms |

SpringShaker is the most physics-complete of the three at the cost of being the heaviest per frame. At 10 simultaneous instances — a realistic maximum for most games — total frame cost is under 0.02ms.

### Memory at 1000 instances

| Module | Peak | Retained after GC |
| --- | --- | --- |
| SpringShaker | ~2.5MB | ~0KB |
| RbxCameraShaker | ~0.6MB | ~925KB |
| Shake | ~0.6MB | ~0KB |

SpringShaker uses more peak memory due to richer physics state per instance, but releases everything completely on recycle. RbxCameraShaker retains ~925KB after GC consistently across multiple runs.

> ⚠️ SpringShaker has been stress tested up to 1,000,000 simultaneous instances. Please do not do this. 1–25 is a sensible maximum for any real game.

---

## References

- [Desmos — SpringShaker oscillator graph](https://www.desmos.com/calculator/r8iharhx3y)
- [Damped Harmonic Oscillator — Wikipedia](https://en.wikipedia.org/wiki/Harmonic_oscillator#Damped_harmonic_oscillator)
- [Resonance — Wikipedia](https://en.wikipedia.org/wiki/Resonance)

## Special Thanks

[Janitor v1.18.3](https://github.com/howmanysmall/Janitor/tree/main) by howmanysmall