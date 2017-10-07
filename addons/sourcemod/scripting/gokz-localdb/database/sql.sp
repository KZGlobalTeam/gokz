/*	
	SQL
	
	SQL query templates.
*/



// =========================  PLAYERS  ========================= //

char sqlite_players_create[] = 
"CREATE TABLE IF NOT EXISTS Players ("
..."SteamID32 INTEGER NOT NULL, "
..."Alias TEXT, "
..."Country TEXT, "
..."IP TEXT, "
..."LastPlayed TIMESTAMP, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Player PRIMARY KEY (SteamID32))";

char mysql_players_create[] = 
"CREATE TABLE IF NOT EXISTS Players ("
..."SteamID32 INTEGER UNSIGNED NOT NULL, "
..."Alias VARCHAR(32), "
..."Country VARCHAR(45), "
..."IP VARCHAR(15), "
..."LastPlayed TIMESTAMP, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Player PRIMARY KEY (SteamID32))";

char sqlite_players_insert[] = 
"INSERT OR IGNORE INTO Players (Alias, Country, IP, SteamID32, LastPlayed) "
..."VALUES ('%s', '%s', '%s', %d, CURRENT_TIMESTAMP)";

char sqlite_players_update[] = 
"UPDATE OR IGNORE Players "
..."SET Alias='%s', Country='%s', IP='%s', LastPlayed=CURRENT_TIMESTAMP "
..."WHERE SteamID32=%d;";

char mysql_players_upsert[] = 
"INSERT INTO Players (Alias, Country, IP, SteamID32, LastPlayed) "
..."VALUES ('%s', '%s', '%s', %d, CURRENT_TIMESTAMP) "
..."ON DUPLICATE KEY UPDATE "
..."SteamID32=VALUES(SteamID32), Alias=VALUES(Alias), Country=VALUES(Country), IP=VALUES(IP), LastPlayed=VALUES(LastPlayed)";



// =========================  OPTIONS  ========================= //

char sqlite_options_create[] = 
"CREATE TABLE IF NOT EXISTS Options ("
..."SteamID32 INTEGER NOT NULL, "
..."Mode INTEGER NOT NULL DEFAULT '1', "
..."Style INTEGER NOT NULL DEFAULT '0', "
..."ShowingTeleportMenu INTEGER NOT NULL DEFAULT '1', "
..."ShowingInfoPanel INTEGER NOT NULL DEFAULT '1', "
..."ShowingKeys INTEGER NOT NULL DEFAULT '0', "
..."ShowingPlayers INTEGER NOT NULL DEFAULT '1', "
..."ShowingWeapon INTEGER NOT NULL DEFAULT '1', "
..."AutoRestart INTEGER NOT NULL DEFAULT '0', "
..."SlayOnEnd INTEGER NOT NULL DEFAULT '0', "
..."Pistol INTEGER NOT NULL DEFAULT '0', "
..."CheckpointMessages INTEGER NOT NULL DEFAULT '0', "
..."CheckpointSounds INTEGER NOT NULL DEFAULT '1', "
..."TeleportSounds INTEGER NOT NULL DEFAULT '0', "
..."ErrorSounds INTEGER NOT NULL DEFAULT '1', "
..."TimerText INTEGER NOT NULL DEFAULT '1', "
..."SpeedText INTEGER NOT NULL DEFAULT '1', "
..."JumpBeam INTEGER NOT NULL DEFAULT '0', "
..."HelpAndTips INTEGER NOT NULL DEFAULT '1', "
..."CONSTRAINT PK_Options PRIMARY KEY (SteamID32), "
..."CONSTRAINT FK_Options_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_options_create[] = 
"CREATE TABLE IF NOT EXISTS Options ("
..."SteamID32 INTEGER UNSIGNED NOT NULL, "
..."Mode TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."Style TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."ShowingTeleportMenu TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."ShowingInfoPanel TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."ShowingKeys TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."ShowingPlayers TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."ShowingWeapon TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."AutoRestart TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."SlayOnEnd TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."Pistol TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."CheckpointMessages TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."CheckpointSounds TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."TeleportSounds TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."ErrorSounds TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."TimerText TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."SpeedText TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."JumpBeam TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."HelpAndTips TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."CONSTRAINT PK_Options PRIMARY KEY (SteamID32), "
..."CONSTRAINT FK_Options_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) ON UPDATE CASCADE ON DELETE CASCADE)";

// Alter 1 - 0.18.0 - Added help and tips option
char sqlite_options_alter1[] = 
"ALTER TABLE Options "
..."ADD HelpAndTips INTEGER NOT NULL DEFAULT '1'";

char mysql_options_alter1[] = 
"ALTER TABLE Options "
..."ADD HelpAndTips TINYINT UNSIGNED NOT NULL DEFAULT '1'";

char sql_options_insert[] = 
"INSERT INTO Options (SteamID32) "
..."VALUES (%d)";

char sql_options_update[] = 
"UPDATE Options "
..."SET Mode=%d, Style=%d, ShowingTeleportMenu=%d, ShowingInfoPanel=%d, ShowingKeys=%d, ShowingPlayers=%d, ShowingWeapon=%d, AutoRestart=%d, SlayOnEnd=%d, Pistol=%d, CheckpointMessages=%d, CheckpointSounds=%d, TeleportSounds=%d, ErrorSounds=%d, TimerText=%d, SpeedText=%d, JumpBeam=%d, HelpAndTips=%d "
..."WHERE SteamID32=%d";

char sql_options_get[] = 
"SELECT Mode, Style, ShowingTeleportMenu, ShowingInfoPanel, ShowingKeys, ShowingPlayers, ShowingWeapon, AutoRestart, SlayOnEnd, Pistol, CheckpointMessages, CheckpointSounds, TeleportSounds, ErrorSounds, TimerText, SpeedText, JumpBeam, HelpAndTips "
..."FROM Options "
..."WHERE SteamID32=%d";



// =========================  JUMPSTATS OPTIONS  ========================= //

char sqlite_jsoptions_create[] = 
"CREATE TABLE IF NOT EXISTS JumpstatsOptions ("
..."SteamID32 INTEGER NOT NULL, "
..."MasterSwitch INTEGER NOT NULL DEFAULT '1', "
..."ChatTier INTEGER NOT NULL DEFAULT '1', "
..."ConsoleTier INTEGER NOT NULL DEFAULT '2', "
..."SoundTier INTEGER NOT NULL DEFAULT '2', "
..."CONSTRAINT PK_JSOptions PRIMARY KEY (SteamID32), "
..."CONSTRAINT FK_JSOptions_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_jsoptions_create[] = 
"CREATE TABLE IF NOT EXISTS JumpstatsOptions ("
..."SteamID32 INTEGER UNSIGNED NOT NULL, "
..."MasterSwitch TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."ChatTier TINYINT UNSIGNED NOT NULL DEFAULT '1', "
..."ConsoleTier TINYINT UNSIGNED NOT NULL DEFAULT '2', "
..."SoundTier TINYINT UNSIGNED NOT NULL DEFAULT '2', "
..."CONSTRAINT PK_JSOptions PRIMARY KEY (SteamID32), "
..."CONSTRAINT FK_JSOptions_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) ON UPDATE CASCADE ON DELETE CASCADE)";

char sql_jsoptions_insert[] = 
"INSERT INTO JumpstatsOptions (SteamID32) "
..."VALUES (%d)";

char sql_jsoptions_update[] = 
"UPDATE JumpstatsOptions "
..."SET MasterSwitch=%d, ChatTier=%d, ConsoleTier=%d, SoundTier=%d "
..."WHERE SteamID32=%d";

char sql_jsoptions_get[] = 
"SELECT MasterSwitch, ChatTier, ConsoleTier, SoundTier "
..."FROM JumpstatsOptions "
..."WHERE SteamID32=%d";



// =========================  MAPS  ========================= //

char sqlite_maps_create[] = 
"CREATE TABLE IF NOT EXISTS Maps ("
..."MapID INTEGER NOT NULL, "
..."Name VARCHAR(32) NOT NULL UNIQUE, "
..."LastPlayed TIMESTAMP, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Maps PRIMARY KEY (MapID))";

char mysql_maps_create[] = 
"CREATE TABLE IF NOT EXISTS Maps ("
..."MapID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, "
..."Name VARCHAR(32) NOT NULL UNIQUE, "
..."LastPlayed TIMESTAMP, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Maps PRIMARY KEY (MapID))";

char sqlite_maps_insert[] = 
"INSERT OR IGNORE INTO Maps (Name, LastPlayed) "
..."VALUES ('%s', CURRENT_TIMESTAMP)";

char sqlite_maps_update[] = 
"UPDATE OR IGNORE Maps "
..."SET LastPlayed=CURRENT_TIMESTAMP "
..."WHERE Name='%s'";

char mysql_maps_upsert[] = 
"INSERT INTO Maps (Name, LastPlayed) "
..."VALUES ('%s', CURRENT_TIMESTAMP) "
..."ON DUPLICATE KEY UPDATE "
..."LastPlayed=CURRENT_TIMESTAMP";

char sql_maps_findid[] = 
"SELECT MapID, Name "
..."FROM Maps "
..."WHERE Name LIKE '%%%s%%' "
..."ORDER BY (Name='%s') DESC, LENGTH(Name) "
..."LIMIT 1";



// =========================  MAPCOURSES  ========================= //

char sqlite_mapcourses_create[] = 
"CREATE TABLE IF NOT EXISTS MapCourses ("
..."MapCourseID INTEGER NOT NULL, "
..."MapID INTEGER NOT NULL, "
..."Course INTEGER NOT NULL, "
..."Created INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_MapCourses PRIMARY KEY (MapCourseID), "
..."CONSTRAINT UQ_MapCourses_MapIDCourse UNIQUE (MapID, Course), "
..."CONSTRAINT FK_MapCourses_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_mapcourses_create[] = 
"CREATE TABLE IF NOT EXISTS MapCourses ("
..."MapCourseID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, "
..."MapID INTEGER UNSIGNED NOT NULL, "
..."Course INTEGER UNSIGNED NOT NULL, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_MapCourses PRIMARY KEY (MapCourseID), "
..."CONSTRAINT UQ_MapCourses_MapIDCourse UNIQUE (MapID, Course), "
..."CONSTRAINT FK_MapCourses_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) ON UPDATE CASCADE ON DELETE CASCADE)";

char sqlite_mapcourses_insert[] = 
"INSERT OR IGNORE INTO MapCourses (MapID, Course) "
..."VALUES (%d, %d)";

char mysql_mapcourses_insert[] = 
"INSERT IGNORE INTO MapCourses (MapID, Course) "
..."VALUES (%d, %d)";



// =========================  TIMES  ========================= //

char sqlite_times_create[] = 
"CREATE TABLE IF NOT EXISTS Times ("
..."TimeID INTEGER NOT NULL, "
..."SteamID32 INTEGER NOT NULL, "
..."MapCourseID INTEGER NOT NULL, "
..."Mode INTEGER NOT NULL, "
..."Style INTEGER NOT NULL, "
..."RunTime INTEGER NOT NULL, "
..."Teleports INTEGER NOT NULL, "
..."Created INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Times PRIMARY KEY (TimeID), "
..."CONSTRAINT FK_Times_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) ON UPDATE CASCADE ON DELETE CASCADE, "
..."CONSTRAINT FK_Times_MapCourseID FOREIGN KEY (MapCourseID) REFERENCES MapCourses(MapCourseID) ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_times_create[] = 
"CREATE TABLE IF NOT EXISTS Times ("
..."TimeID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, "
..."SteamID32 INTEGER UNSIGNED NOT NULL, "
..."MapCourseID INTEGER UNSIGNED NOT NULL, "
..."Mode TINYINT UNSIGNED NOT NULL, "
..."Style TINYINT UNSIGNED NOT NULL, "
..."RunTime INTEGER UNSIGNED NOT NULL, "
..."Teleports SMALLINT UNSIGNED NOT NULL, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Times PRIMARY KEY (TimeID), "
..."CONSTRAINT FK_Times_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) ON UPDATE CASCADE ON DELETE CASCADE, "
..."CONSTRAINT FK_Times_MapCourseID FOREIGN KEY (MapCourseID) REFERENCES MapCourses(MapCourseID) ON UPDATE CASCADE ON DELETE CASCADE)";

char sql_times_insert[] = 
"INSERT INTO Times (SteamID32, MapCourseID, Mode, Style, RunTime, Teleports) "
..."SELECT %d, MapCourseID, %d, %d, %d, %d "
..."FROM MapCourses "
..."WHERE MapID=%d AND Course=%d"; 