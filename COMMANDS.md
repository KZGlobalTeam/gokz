# Commands

### gokz-core

 * `!options`/`!o` - Open the options menu.
 * `!checkpoint` - Set a checkpoint.
 * `!gocheck` - Teleport to your current checkpoint.
 * `!prev` - Go back a checkpoint.
 * `!next` - Go forward a checkpoint.
 * `!undo` - Undo teleport.
 * `!start`/`!restart`/`!r` - Teleport to your start position.
 * `!setstartpos`/`!ssp` - Set your custom start position to your current position.
 * `!clearstartpos`/`!csp` - Clear your custom start position.
 * `!main`/`!m` - Teleport to the start of the main course.
 * `!bonus`/`!b` - Teleport to the start of a bonus. Usage: `!b <#bonus>`
 * `!pause`/`!resume` - Toggle pausing your timer and stopping you in your position.
 * `!stop` - Stop your timer.
 * `!autorestart` - Toggle auto restart upon teleporting to start.
 * `!mode` - Open the movement mode selection menu.
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

 * `!hide` - Toggle the visibility of other players.
 * `!stopsound` - Stop all sounds e.g. map soundscapes (music).

### gokz-pistol

 * `!pistol` - Open the pistol selection menu.

### gokz-measure

 * `!measure` - Open the distance measurement menu.

### gokz-goto

 * `!goto` - Teleport to another player. Usage: `!goto <player>`

### gokz-saveloc

 * `!saveloc` - Save location. Usage: `!saveloc <name>`
 * `!loadloc` - Load location. Usage: `!loadloc <#id OR name>`
 * `!locmenu` - Open location menu.
 * `!nameloc` - Name location. Usage: `!nameloc <#id> <name>`

### gokz-spec

 * `!spec` - Spectate another player. Usage `!spec <player>`
 * `!specs`/`!speclist` - List currently spectating players in chat.

### gokz-jumpstats

 * `!jumpstats`/`!js`/`!ljstats` - Open the jumpstats options menu.

### gokz-anticheat

 * `!bhopcheck` - Show bunnyhop stats report including perf ratio and scroll pattern.

### gokz-replays

 * `!replay` - Open the replay loading menu.

### gokz-racing

 * `!accept` - Accept an incoming race request.
 * `!decline` - Decline an incoming race request.
 * `!surrender` - Surrender your race.
 * `!race` - Open the race hosting menu.
 * `!duel`/`!challenge` - Open the duel menu.
 * `!abort` - Abort the race you are hosting.

### gokz-localranks

Many of these commands return results for your currently selected mode.

 * `!top` - Open a menu showing the top record holders
 * `!maptop` - Open a menu showing the top main course times of a map. Usage: `!maptop <map>`
 * `!bmaptop` - Open a menu showing the top bonus times of a map. Usage: `!btop <#bonus> <map>`
 * `!pb` - Show PB main course times and ranks in chat. Usage: `!pb <map> <player>`
 * `!bpb` - Show PB bonus times and ranks in chat. Usage: `!bpb <#bonus> <map> <player>`
 * `!wr` - Show main course record times in chat. Usage: `!wr <map>`
 * `!bwr` - Show bonus record times in chat. Usage: `!bwr <#bonus> <map>`
 * `!avg` - Show the average main course run time in chat. Usage `!avg <map>`
 * `!bavg` - Show the average bonus run time in chat. Usage `!bavg <#bonus> <map>`
 * `!pc` - Show course completion in chat. Usage: `!pc <player>`
 * `!rr`/`!latest` - Open a menu showing recently broken records.

### gokz-global

 * `!globalcheck`/`!gc` - Show whether global records are currently enabled in chat.
 * `!tier` - Show the map's tier in chat.
 * `!gr`/`!gwr` - Show main course global record times in chat. Usage: `!gr <map>`
 * `!gbr`/`!gbwr` - Show bonus global record times in chat. Usage: `!bgr <#bonus> <map>`
 * `!gmaptop` - Open a menu showing the top global main course times of a map. Usage: `!gmaptop <map>`
 * `!gbmaptop` - Open a menu showing the top global bonus times of a map. Usage: `!gbmaptop <#bonus> <map>`

# Admin Commands

### gokz-localdb

 * `!setcheater` - Set a SteamID as a cheater. Usage: `!setcheater <STEAM_1:X:X>`
 * `!setnotcheater` - Set a SteamID as not a cheater. Usage: `!setnotcheater <STEAM_1:X:X>`

### gokz-localranks

 * `!updatemappool` - Update the ranked map pool with the list of maps in cfg/sourcemod/gokz/mappool.cfg.