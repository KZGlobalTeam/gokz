# Plugins

GOKZ is comprised of several smaller plugins. **It is highly recommended that servers run ALL of the available plugins.**

Below is a brief description what each plugin does. Please note that things may change significantly as new features are added and in future major versions of GOKZ.

### gokz-core

Provides all core functionality such as the timer, map button hooks, checkpoint and teleport system, and many of the features considered essential to the GOKZ experience. **Required for all other plugins.**

### gokz-mode-* (Modes)

Each mode plugin provides one mode for GOKZ. These plugins can be used without any other GOKZ plugin (still requires MovementAPI) to apply their mechanics to all players on the server at all times. **At least one mode plugin is required.**

### gokz-localdb
Stores and loads player options in a database. Also stores maps and their courses as they are loaded in and saves all times achieved by players. Does not provide any client-facing functionality.

### gokz-localranks

Provides client-facing functionality of the local database, such as personal bests, time rankings, server record announcements, and menus to browse the leaderboards. **Requires gokz-localdb.**

### gokz-jumpstats

Provides detailed measurements, statistics and feedback to the player about the distance, speed and strafes of their jumps.

### gokz-antimacro

Tracks player inputs and automatically bans them if they are, without a doubt, using a macro or cheat.

### gokz-replays

Records and allows playback the player's movement of the server's record times. **Requires gokz-localranks.**

### gokz-globals

Uses the [GlobalAPI SourceMod plugin](https://bitbucket.org/kztimerglobalteam/globalrecordssmplugin) to link the server to a global database, allowing players to compete across servers by submitting their timer to a global leaderboard. Also enforces several configuration restrictions and a global banlist. **Requires gokz-replays and gokz-antimacro. Integrates with gokz-localranks menus.**

### gokz-tips

Prints help messages to chat periodically. The messages are read from translation files.