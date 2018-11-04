/*	
	SQL
	
	SQL query templates.
*/



// =====[ PLAYERS ]=====

char sqlite_players_create[] = 
"CREATE TABLE IF NOT EXISTS Players ("
..."SteamID32 INTEGER NOT NULL, "
..."Alias TEXT, "
..."Country TEXT, "
..."IP TEXT, "
..."Cheater INTEGER NOT NULL DEFAULT '0', "
..."LastPlayed TIMESTAMP NULL DEFAULT NULL, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Player PRIMARY KEY (SteamID32))";

char mysql_players_create[] = 
"CREATE TABLE IF NOT EXISTS Players ("
..."SteamID32 INTEGER UNSIGNED NOT NULL, "
..."Alias VARCHAR(32), "
..."Country VARCHAR(45), "
..."IP VARCHAR(15), "
..."Cheater TINYINT UNSIGNED NOT NULL DEFAULT '0', "
..."LastPlayed TIMESTAMP NULL DEFAULT NULL, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Player PRIMARY KEY (SteamID32))";

// 1.0.0 - Added Cheater column
char sqlite_players_alter1[] = 
"ALTER TABLE Players "
..."ADD Cheater INTEGER NOT NULL DEFAULT '0'";

// 1.0.0 - Added Cheater column
char mysql_players_alter1[] = 
"ALTER TABLE Players "
..."ADD Cheater TINYINT UNSIGNED NOT NULL DEFAULT '0'";

char sqlite_players_insert[] = 
"INSERT OR IGNORE INTO Players (Alias, Country, IP, SteamID32, LastPlayed) "
..."VALUES ('%s', '%s', '%s', %d, CURRENT_TIMESTAMP)";

char sqlite_players_update[] = 
"UPDATE OR IGNORE Players "
..."SET Alias='%s', Country='%s', IP='%s', LastPlayed=CURRENT_TIMESTAMP "
..."WHERE SteamID32=%d";

char mysql_players_upsert[] = 
"INSERT INTO Players (Alias, Country, IP, SteamID32, LastPlayed) "
..."VALUES ('%s', '%s', '%s', %d, CURRENT_TIMESTAMP) "
..."ON DUPLICATE KEY UPDATE "
..."SteamID32=VALUES(SteamID32), Alias=VALUES(Alias), Country=VALUES(Country), IP=VALUES(IP), LastPlayed=VALUES(LastPlayed)";

char sql_players_get_cheater[] = 
"SELECT Cheater "
..."FROM Players "
..."WHERE SteamID32=%d";

char sql_players_set_cheater[] = 
"UPDATE Players "
..."SET Cheater=%d "
..."WHERE SteamID32=%d";



// =====[ MAPS ]=====

char sqlite_maps_create[] = 
"CREATE TABLE IF NOT EXISTS Maps ("
..."MapID INTEGER NOT NULL, "
..."Name VARCHAR(32) NOT NULL UNIQUE, "
..."LastPlayed TIMESTAMP NULL DEFAULT NULL, "
..."Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
..."CONSTRAINT PK_Maps PRIMARY KEY (MapID))";

char mysql_maps_create[] = 
"CREATE TABLE IF NOT EXISTS Maps ("
..."MapID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, "
..."Name VARCHAR(32) NOT NULL UNIQUE, "
..."LastPlayed TIMESTAMP NULL DEFAULT NULL, "
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



// =====[ MAPCOURSES ]=====

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



// =====[ TIMES ]=====

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