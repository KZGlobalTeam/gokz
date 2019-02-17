# GOKZ SourceMod Plugins (CS:GO)

GOKZ a set of [SourceMod](https://www.sourcemod.net/about.php) plugins exclusively for Counter-Strike: Global Offensive servers. It implements the KZ (Kreedz) game mode, which involves [speedrunning](https://en.wikipedia.org/wiki/Speedrun) through custom maps.

## Features

 * **Timer** - Times runs by automatically detecting the use of start and end buttons in KZ maps.
 * **Movement Modes** - Custom movement mechanics. Includes Vanilla, SimpleKZ, and KZTimer modes.
    * Mode plugins can be used alone (with only MovementAPI) to apply their mechanics at all times.
 * **Jumpstats** - Detailed statistics of your jumps and each individual air strafe.
 * **Customisable Experience** - Tonnes of options to provide the best possible experience for players. 
 * **Database Support** - Store run times, options and more using either a MySQL or SQLite database.
 * **GlobalAPI Support** - Submit run times to the GlobalAPI so that players may compete across servers.
 * **Replays** - Record replays of the server's fastest times and use bots to play them back.
 * **Anti-Macro** - Detect and auto-ban blatant users of bhop macros and cheats (SourceBans++ supported).
 * Map bonus support, HUD, teleport menu, noclip, !goto, !measure and much, much more.

For more information about what each plugin does, please see [PLUGINS.md](PLUGINS.md).

## Usage

### Server Requirements

 * 128 Tick (`-tickrate 128`)
 * [SourceMod ^1.9](https://www.sourcemod.net/downloads.php?branch=stable)
 * clientprefs Extension (comes packaged with SourceMod)
 * [DHooks Extension ^2.2.0](https://forums.alliedmods.net/showthread.php?t=180114)
 * [MovementAPI Plugin ^1.1.2](https://github.com/danzayau/MovementAPI)
 * Optional - [GlobalAPI Plugin](https://bitbucket.org/kztimerglobalteam/globalrecordssmplugin) (required for gokz-globals plugin)
 * Optional - [Cleaner Extension](https://github.com/Accelerator74/Cleaner) (prevent "Datatable warning" server console spam)
 * Optional - [Updater Plugin](https://forums.alliedmods.net/showthread.php?t=169095) (auto-update the plugins)

### Installing

 * Ensure your server is up to date and meets the above requirements.
 * Download and extract `GOKZ-latest.zip` from [Downloads](https://bitbucket.org/kztimerglobalteam/gokz/downloads/) to `csgo`.
 * Add a MySQL or SQLite database called `gokz` to `csgo/addons/sourcemod/configs/databases.cfg`.
 * Configure the `clientprefs` database as desired (can be same database).
 * When the plugins first load, various configuration files will be auto-generated and can be found in `csgo/cfg/sourcemod/gokz`.
 * Use the `!updatemappool` or `sm_updatemappool` in console to populate the ranked map pool with those in `csgo/cfg/sourcemod/gokz/gokz-localranks-mappool.cfg`.

### Updating

 * Minor updates - Download and extract `GOKZ-latest-upgrade.zip` from [Downloads](https://bitbucket.org/kztimerglobalteam/gokz/downloads/) to `csgo`.
 * Major updates - Check the new version's release notes for specific instructions.

### Commands

Please see [COMMANDS.md](COMMANDS.md) for a list of player and admin commands.

### Mapping

To add a timer button to a map, use a `func_button` with a specific name.

 * Start button is named `climb_startbutton`.
 * End button is named `climb_endbutton`.
 * Bonus start buttons are named `climb_bonusX_startbutton` where X is the bonus number.
 * Bonus end buttons are named `climb_bonusX_endbutton` where X is the bonus number.

**TIP** - Enable both the `Don't move` and `Toggle` flags to easily avoid any usability issues.

## Contributing

All contributions are greatly appreciated! If you are interested, please see [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

## Authors

 * **DanZay** - *Initial Work, Maintenance, Management* - [Steam](https://steamcommunity.com/id/DanZay/)
 * **KZTimerGlobal Team** - *Continuing Development* - [BitBucket](https://bitbucket.org/kztimerglobalteam/profile/members)

## Links

[Official Wiki](https://bitbucket.org/kztimerglobalteam/gokz/wiki)

[Steam Group](https://steamcommunity.com/groups/GOKZTimer)

[CS:GO KZ Discord](https://www.discord.gg/csgokz)