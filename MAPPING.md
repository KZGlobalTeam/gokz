# Mapping

## Timer buttons

- Time starts when the player activates the start timer.
- Time ends when the player activates the end timer.
- Timer buttons **do** create virtual buttons (timer tech).

#### To implement timer buttons, the following are required:

- Create a [func_button](https://developer.valvesoftware.com/wiki/Func_button "Valve Developer Community Wiki reference") entity.
- Name the entity as either:
	- `climb_startbutton` for the **start** of the **main course**.
	- `climb_endbutton` for the **end** of the **main course**.
	- `climb_bonusX_startbutton` for the **start** of a **bonus course** where X is the bonus number.
	- `climb_bonusX_endbutton` for the **end** of a **bonus course** where X is the bonus number.
- Enable both the `Don't move` and `Toggle` flags to avoid usability issues.

---

## Timer zones

- Time starts when the player leaves the zone.
- Time ends when the player enters the zone.
- Timer zones **do not** create virtual buttons (timer tech).

#### To implement timer zones, the following are required:

- Create a [trigger_multiple](https://developer.valvesoftware.com/wiki/Trigger_multiple "Valve Developer Community Wiki reference") entity.
- Name the entity as either:
	- `climb_startzone` for the **start** of the **main course**.
	- `climb_endzone` for the **end** of the **main course**.
	- `climb_bonusX_startzone` for the **start** of a **bonus course** where X is the bonus number.
	- `climb_bonusX_endzone` for the **end** of a **bonus course** where X is the bonus number.

#### Things to keep in mind:

- Timer zones can act as [Course starts](#markdown-header-course-starts)
	- Entering a **start** timer zone will stop the player's current timer.
	- Entering a **start** timer zone will set the player's start position to the zone.
- Start zones can be left midair as long as a perfect bunnyhop is **not** hit.
- Multiple start timer zones should not be possible to be activated at once to avoid usability issues.

---

## Course starts

Course starts mark where players will be teleported when using the following commands:

- `!m` command to teleport to the **main course**.
- `!b <number>` command to teleport to the specified **bonus course**.

#### To implement course starts, the following are required:

- Create an [info_teleport_destination](https://developer.valvesoftware.com/wiki/Info_teleport_destination "Valve Developer Wiki reference") entity.
- Name the entity as either:
	- `climb_start` for the **main course**.
	- `climb_bonusX_start` for a **bonus course** where X is the bonus number.
- Set `Pitch Yaw Roll (Y Z X)` to the angles you wish to teleport the player into.
