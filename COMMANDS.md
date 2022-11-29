# Commands

### gokz-core

 * `!options`/`!o` - Open the options menu.
 * `!checkpoint` - Set a checkpoint.
 * `!gocheck` - Teleport to your current checkpoint.
 * `!prev` - Go back a checkpoint.
 * `!next` - Go forward a checkpoint.
 * `!undo` - Undo teleport.
 * `!start`/`!restart`/`!r` - Teleport to your start position.
 * `!searchstart` - Search for the start timer of a course and teleport to it. Usage: `!searchstart <main/#course>`
 * `!end` - Teleport to the end timer of a course. Usage: `!end <main/#course>`.
 * `!setstartpos`/`!ssp` - Set your custom start position to your current position.
 * `!clearstartpos`/`!csp` - Clear your custom start position.
 * `!main`/`!m` - Teleport to the start of the main course.
 * `!bonus`/`!b` - Teleport to the start of a bonus. Usage: `!b <#bonus>`
 * `!pause`/`!resume` - Toggle pausing your timer and stopping you in your position.
 * `!stop` - Stop your timer.
 * `!virtualbuttonindicators`/`!vbi` - Toggle virtual button indicators.
 * `!virtualbuttons`/`!vb` - Toggle locking virtual buttons, preventing them from being moved.
 * `!mode` - Open the movement mode selection menu.
 * `!vanilla`/`!vnl`/`!v` - Switch to the Vanilla mode.
 * `!simplekz`/`!skz`/`!s` - Switch to the SimpleKZ mode.
 * `!kztimer`/`!kzt`/`!k` - Switch to the KZTimer mode.
 * `!nc` - Toggle noclip.
 * `!ncnt` - Toggle noclip-notrigger that ignores triggers.
 * `+noclip` - Noclip (bind a key to it).
 * `+noclipnt` - Noclip-notrigger that ignores triggers (bind a key to it).
 * `!sg`/`!safe`/`!safeguard` - Toggle safeguard.
 * `!pro` - Toggle safeguard for PRO runs.

### gokz-hud

 * `!menu`/`!cpmenu` - Toggle the visibility of the simple teleport menu.
 * `!adv` - Toggle the visibility of the advanced teleport menu.
 * `!panel` - Toggle visibility of the centre information panel.
 * `!timerstyle` - Toggle the style of the timer text.
 * `!timertype` - Toggle the PRO/NUB indicator for the timer text.
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

 * `!measure`/`!measuremenu` - Open the distance measurement menu.
 * `+measure` - Start measuring (bind to a key)
 * `!measureblock` - Measure the gap of a block you're currently aiming at.

### gokz-goto

 * `!goto` - Teleport to another player. Usage: `!goto <player>`

### gokz-saveloc

 * `!saveloc` - Save location. Usage: `!saveloc <name>`
 * `!loadloc` - Load location. Usage: `!loadloc <#id OR name>`
 * `!prevloc` - Go back to the previous location.
 * `!nextloc` - Go forward to the next location.
 * `!locmenu` - Open location menu.
 * `!nameloc` - Name location. Usage: `!nameloc <#id> <name>`

### gokz-paint

 * `!paint` - Place a single paint (colored circle)
 * `+paint` - Start painting (bind to a key)
 * `!paintoptions` - Open paint options
 * `r_cleardecals` - Console command to clear all decals (including paints)

### gokz-spec

 * `!spec` - Spectate another player. Usage `!spec <player>`
 * `!specs`/`!speclist` - List currently spectating players in chat.

### gokz-jumpstats

 * `!jso` - Open the jumpstats options menu.
 * `!jsalways` - Toggle the 'Always-on' jumpstat mode.

### gokz-replays

 * `!replay` - Open the replay loading menu.
 * `!replaycontrols`/`!rpcontrols` - Toggle the replay control menu (when in control of a replay bot).
 * `!replaygoto`/`!rpgoto` - Skip to a specific time in the replay. Usage: `!rpgoto hh:mm:ss`

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
 * `!bmaptop`/`!bonustop`/`!btop` - Open a menu showing the top bonus times of a map. Usage: `!btop <#bonus> <map>`
 * `!pb` - Show PB main course times and ranks in chat. Usage: `!pb <map> <player>`
 * `!bpb` - Show PB bonus times and ranks in chat. Usage: `!bpb <#bonus> <map> <player>`
 * `!wr` - Show main course record times in chat. Usage: `!wr <map>`
 * `!bwr` - Show bonus record times in chat. Usage: `!bwr <#bonus> <map>`
 * `!avg` - Show the average main course run time in chat. Usage `!avg <map>`
 * `!bavg` - Show the average bonus run time in chat. Usage `!bavg <#bonus> <map>`
 * `!pc` - Show course completion in chat. Usage: `!pc <player>`
 * `!rr`/`!latest` - Open a menu showing recently broken records.
 * `!jumptop`/`!jstop` - Open a menu showing the top jumpstats.
 * `!jumpstats`/`!js` - Open a menu showing jumpstat PBs. Usage: `!js <jumper>`
 * `!ljpb` - Show PB Long Jump in chat. Usage: `!ljpb <jumper>`
 * `!bhpb` - Show PB Bunnyhop in chat. Usage: `!bhpb <jumper>`
 * `!lbhpb` - Show PB Lowpre Bunnyhop in chat. Usage: `!lbhpb <jumper>`
 * `!mbhpb` - Show PB Multi Bunnyhop in chat. Usage: `!mbhpb <jumper>`
 * `!wjpb` - Show PB Weird Jump in chat. Usage: `!wjpb <jumper>`
 * `!lwjpb` - Show PB Lowpre Weird Jump in chat. Usage: `!lwjpb <jumper>`
 * `!lajpb` - Show PB Ladder Jump in chat. Usage: `!lajpb <jumper>`
 * `!lahpb` - Show PB Ladderhop in chat. Usage: `!lahpb <jumper>`
 * `!jbpb` - Show PB Jumpbug in chat. Usage: `!jbpb <jumper>`

### gokz-global

 * `!globalcheck`/`!gc` - Show whether global records are currently enabled in chat.
 * `!tier` - Show the map's tier in chat.
 * `!gr`/`!gwr` - Show main course global record times in chat. Usage: `!gr <map>`
 * `!gbr`/`!gbwr` - Show bonus global record times in chat. Usage: `!bgr <#bonus> <map>`
 * `!gpb` - Show your personal best for a map. Usage: `!gpb <map>`
 * `!gbpb` - Show your personal best for a bonus on the current map. Usage: `!gbpb <#bonus>`
 * `!gmaptop` - Open a menu showing the top global main course times of a map. Usage: `!gmaptop <map>`
 * `!gbmaptop` - Open a menu showing the top global bonus times of a map. Usage: `!gbmaptop <#bonus> <map>`

### gokz-profile

 * `!profile`/`!p` - Open the profile of a player. Usage: `!p <player>`
 * `!profileoptions`/`!pfo` - Open the profile options menu.
 * `!ranks` - Show all available ranks and the points required for them.

# Admin Commands

### gokz-anticheat

 * `!bhopcheck` - Show bunnyhop stats report including perf ratio and scroll pattern.

### gokz-localdb

 * `!savetimersetup`/`!sts` - Save the current timer setup (start position and virtual buttons) to the database.
 * `!loadtimersetup`/`!lts` - Load & lock the timer setup (start position and virtual buttons) from the database.
 * `!setcheater` - Set a SteamID as a cheater. Usage: `!setcheater <STEAM_1:X:X>`
 * `!setnotcheater` - Set a SteamID as not a cheater. Usage: `!setnotcheater <STEAM_1:X:X>`
 * `!deletebestjump` - Remove the top jumpstat of a SteamID. Usage: `!deletebestjump <STEAM_1:X:X> <mode> <jump type> <block?>`
 * `!deletealljumps` - Remove all jumpstats of a SteamID. Usage: `!deletealljumps <STEAM_1:X:X>`
 * `!deletejump` - Remove a jumpstat by it's id. Usage: `!deletejump <id>`
 * `!deletetime` - Remove a time by it's id. Usage: `!deletetime <id>`

### gokz-localranks

 * `!updatemappool` - Update the ranked map pool with the list of maps in cfg/sourcemod/gokz/gokz-localranks-mappool.cfg.
