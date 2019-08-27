# Mapping

## Timer Buttons

Timer buttons start or end the player's timer when activated.

Timer buttons create a virtual button (for "timer tech") only when *use* activated.

To add a timer button to a map, use a `func_button` with a specific name.

 * Start buttons are named `climb_startbutton`.
 * End buttons are named `climb_endbutton`.
 * Bonus start buttons are named `climb_bonusX_startbutton` where X is the bonus number.
 * Bonus end buttons are named `climb_bonusX_endbutton` where X is the bonus number.

To avoid usability issues, enable both the `Don't move` and `Toggle` flags on the `func_button`.

## Timer Zones

Start zones start the player's timer when they leave them.

End zones end the player's timer when they enter them.

Start zones allow the timer to be started in midair, unless they have hit a perfect bunnyhop.

Timer zones do not create a virtual button (for "timer tech") when activated.

To add a timer zone to a map, use a `trigger_multiple` with a specific name.

 * Start zones are named `climb_startzone`.
 * End zones are named `climb_endzone`.
 * Bonus start zones are named `climb_bonusX_startzone` where X is the bonus number.
 * Bonus end zones are named `climb_bonusX_endzone` where X is the bonus number.

Entering a start zone will stop the player's timer and set their start position to the start of that course (see Course Starts).

To avoid usability issues, ensure it is impossible for the player to be in multiple start zones at once.

## Course Starts

Course starts mark where players will be placed when they are teleported to a course e.g. using the `!b` command.

To add a course start, use an `info_teleport_destination` with a specific name.

 * Main course start is named `climb_start`.
 * Bonus course starts are named `climb_bonusX_start` where X is the bonus number.

Set the angles to an appropriate direction as that is where the player will face.