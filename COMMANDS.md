# Commands

### gokz-core

 * `!options`/`!o` - Open the options menu.
 * `!checkpoint` - Set a checkpoint.
 * `!gocheck` - Teleport to your current checkpoint.
 * `!prev` - Go back a checkpoint.
 * `!next` - Go forward a checkpoint.
 * `!pause`/`!resume` - Toggle pausing your timer and stopping you in your position.
 * `!undo` - Undo teleport.
 * `!start`/`!restart`/`!r` - Teleport to the start of the map.
 * `!stop` - Stop your timer.
 * `!autorestart` - Toggle auto restart upon teleporting to start.
 * `!setstartpos`/`!ssp` - Set your current position as your custom start position.
 * `!clearstartpos`/`!csp` - Clear your custom start position.
 * `!mode` - Opens up the movement mode selection menu.
 * `!vanilla`/`!vnl`/`!v` - Switch to the Vanilla mode.
 * `!simplekz`/`!skz`/`!s` - Switch to the SimpleKZ mode.
 * `!kztimer`/`!kzt`/`!k` - Switch to the KZTimer mode.
 * `!nc` - Toggle noclip.
 * `+noclip` - Noclip (bind a key to it).

### gokz-hud

 * `!menu`/`!cpmenu` - Toggle the visibility of the simple teleport menu.
 * `!adv` - Toggle the visibility of the advanced teleport menu.
 * `!panel` - Toggle visibility of the centre information panel.
 * `!speed` - Toggle visibility of your speed and jump pre-speed.
 * `!hideweapon` - Toggle visibility of your weapon.

### gokz-tips

 * `!tips` - Toggle seeing help and tips.

### gokz-quiet

 * `!hide` - Toggles the visibility of other players.
 * `!stopsound` - Stop all sounds e.g. map soundscapes (music).

### gokz-pistol

 * `!pistol` - Open the pistol selection menu.

### gokz-measure

 * `!measure` - Open the distance measurement menu.

### gokz-goto

 * `!goto` - Teleport to another player. Usage: `!goto <player>`

### gokz-spec

 * `!spec` - Spectate another player. Usage `!spec <player>`
 * `!specs`/`!speclist` - List currently spectating players in chat.

### gokz-jumpstats

 * `!jumpstats`/`!js`/`!ljstats` - Opens the jumpstats options menu.

### gokz-replays

 * `!replay` - Opens the replay loading menu.

### gokz-racing

 * `!accept` - Accept an incoming race request.
 * `!decline` - Decline an incoming race request.
 * `!surrender` - Surrender your race.
 * `!race` - Open the race hosting menu.
 * `!duel`/`!challenge` - Open the duel menu.
 * `!abort` - Abort the race you are hosting.

### gokz-localranks

Many of these commands return results for your currently selected mode.

 * `!top` - Opens a menu showing the top record holders
 * `!maptop` - Opens a menu showing the top times of a map. Usage: `!maptop <map>`
 * `!bmaptop` - Opens a menu showing the top bonus times of a map. Usage: `!btop <#bonus> <map>`
 * `!pb` - Prints map times and ranks to chat. Usage: `!pb <map> <player>`
 * `!bpb` - Prints PB bonus times and ranks to chat. Usage: `!bpb <#bonus> <map> <player>`
 * `!wr` - Prints map record times to chat. Usage: `!wr <map>`
 * `!bwr` - Prints bonus record times to chat. Usage: `!bwr <#bonus> <map>`
 * `!avg` - Prints the average map run time to chat. Usage `!avg <map>`
 * `!bavg` - Prints the average bonus run time to chat. Usage `!bavg <#bonus> <map>`
 * `!pc` - Prints map completion to chat. Usage: `!pc <player>`
 * `!rr`/`!latest` - Opens a menu showing recently broken records.

### gokz-global

 * `!globalcheck`/`!gc` - Prints whether global records are currently enabled.
 * `!tier` - Prints the map's tier to chat.
 * `!gr`/`!gwr` - Prints a map's global record times. Usage: `!gr <map>`
 * `!gbr`/`!gbwr` - Prints a map's global bonus record times. Usage: `!bgr <#bonus> <map>`
 * `!gmaptop` - Opens a menu showing the top global times of a map. Usage: `!gmaptop <map>`
 * `!gbmaptop` - Opens a menu showing the top global bonus times of a map. Usage: `!gbmaptop <#bonus> <map>`

# Admin Commands

### gokz-localdb

 * `!setcheater` - Sets a SteamID as a cheater. Usage: `!setcheater <STEAM_1:X:X>`
 * `!setnotcheater` - Sets a SteamID as not a cheater. Usage: `!setnotcheater <STEAM_1:X:X>`

### gokz-localranks

 * `!updatemappool` - Updates the ranked map pool with the list of maps in cfg/sourcemod/gokz/mappool.cfg.