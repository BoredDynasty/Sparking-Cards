# Train Module Documentation

The `train.luau` module is a server-side orchestrator for managing advanced, physics-based trains in Roblox. It supports multiple train instances, multi-carriage coupling, automatic station routing, and dynamic acceleration/deceleration.

## Setup Instructions

### 1. Workspace Organization
- **Station Sensors**: Create a folder named `StationSensors` in `Workspace`. All your station sensor parts should be placed here.
- **Trains**: While the service can discover trains throughout the Workspace, it's recommended to place them in a `Trains` folder for better organization.

### 2. Station Configuration
Each station is defined by a `BasePart` named `StationSensor`. Configure it using the following **Attributes**:

| Attribute | Type | Description |
| :--- | :--- | :--- |
| `NextStation` | String | The name of the next `StationSensor` in the line. |
| `DepartDirection` | Number | `1` for forward, `-1` for reverse. |
| `LeftDoors` | Boolean | `true` to open left doors, `false` for right. |
| `LineName` | String | (Optional) The name of the train line for displays. |
| `SetLine` | Number | (Optional) The line number for displays. |
| `DoorOpenDuration` | Number | Seconds the doors remain open. |
| `StationStopDuration`| Number | Total seconds the train stays at the station. |

### 3. Train Model Structure
A valid train model should have:
- An **Engine** part (BasePart).
- A **VehicleSeat**.
- (Optional) **Carriages**: Models parented under a folder named `Carriages` or marked with the `IsTrainCarriage` attribute.
- (Optional) **Doors**: Grouped in models named `LeftDoors` or `RightDoors` within carriages.
- (Optional) **Lights**: Grouped in a folder named `Lights` with parts named `A` (front) or `B` (back).

## How it Works

### Physics and Coupling
The module uses `BallSocketConstraints` to connect multiple carriages. Each carriage is internally welded using a `weld-utility` and then chained to the next, allowing the train to navigate curves realistically.

### Automatic Movement
1. **Initial Search**: Upon creation, the train looks for the nearest `StationSensor` in `Workspace.StationSensors`.
2. **Acceleration**: The train accelerates at a "comfort" rate until it reaches its `MaxSpeed`.
3. **Deceleration**: The train dynamically calculates its braking distance. When it nears the `target_station`, it gradually slows down to a complete halt exactly at the sensor.
4. **Sequencing**: After stopping at a station, the train identifies the next target using the `NextStation` attribute.

### Audio System
The module provides spatial audio parented to the train's engine:
- **Ambient**: A looping background track that scales in volume with speed.
- **Clattering**: A speed-dependent track that increases in both volume and pitch as the train moves faster.
- **Brakes/Starting**: One-shot SFX triggered during station events.

## Example Usage

The module returns a `TrainService` singleton that automatically initializes. You usually don't need to call methods manually, but you can interact with it as follows:

```lua
local TrainService = require(path.to.train)

-- The service automatically handles train registration and lifecycle.
-- You can configure your train models with attributes in the editor.
```

### Adding a New Carriage Programmatically
If you want a model to be recognized as a carriage, simply add the attribute:
```lua
model:SetAttribute("IsTrainCarriage", true)
```
The `TrainService` will detect the new model and integrate it into the nearest train's physical chain.
