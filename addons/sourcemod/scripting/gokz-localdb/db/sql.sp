/*
	SQL query templates.
*/



// =====[ PLAYERS ]=====

char sqlite_players_create[] = "\
CREATE TABLE IF NOT EXISTS Players ( \
    SteamID32 INTEGER NOT NULL, \
    Alias TEXT, \
    Country TEXT, \
    IP TEXT, \
    Cheater INTEGER NOT NULL DEFAULT '0', \
    LastPlayed TIMESTAMP NULL DEFAULT NULL, \
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Player PRIMARY KEY (SteamID32))";

char mysql_players_create[] = "\
CREATE TABLE IF NOT EXISTS Players ( \
    SteamID32 INTEGER UNSIGNED NOT NULL, \
    Alias VARCHAR(32), \
    Country VARCHAR(45), \
    IP VARCHAR(15), \
    Cheater TINYINT UNSIGNED NOT NULL DEFAULT '0', \
    LastPlayed TIMESTAMP NULL DEFAULT NULL, \
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Player PRIMARY KEY (SteamID32))";

char sqlite_players_insert[] = "\
INSERT OR IGNORE INTO Players (Alias, Country, IP, SteamID32, LastPlayed) \
    VALUES ('%s', '%s', '%s', %d, CURRENT_TIMESTAMP)";

char sqlite_players_update[] = "\
UPDATE OR IGNORE Players \
    SET Alias='%s', Country='%s', IP='%s', LastPlayed=CURRENT_TIMESTAMP \
    WHERE SteamID32=%d";

char mysql_players_upsert[] = "\
INSERT INTO Players (Alias, Country, IP, SteamID32, LastPlayed) \
    VALUES ('%s', '%s', '%s', %d, CURRENT_TIMESTAMP) \
    ON DUPLICATE KEY UPDATE \
    SteamID32=VALUES(SteamID32), Alias=VALUES(Alias), Country=VALUES(Country), \
    IP=VALUES(IP), LastPlayed=VALUES(LastPlayed)";

char sql_players_get_cheater[] = "\
SELECT Cheater \
    FROM Players \
    WHERE SteamID32=%d";

char sql_players_set_cheater[] = "\
UPDATE Players \
    SET Cheater=%d \
    WHERE SteamID32=%d";



// =====[ MAPS ]=====

char sqlite_maps_create[] = "\
CREATE TABLE IF NOT EXISTS Maps ( \
    MapID INTEGER NOT NULL, \
    Name VARCHAR(32) NOT NULL UNIQUE, \
    LastPlayed TIMESTAMP NULL DEFAULT NULL, \
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Maps PRIMARY KEY (MapID))";

char mysql_maps_create[] = "\
CREATE TABLE IF NOT EXISTS Maps ( \
    MapID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, \
    Name VARCHAR(32) NOT NULL UNIQUE, \
    LastPlayed TIMESTAMP NULL DEFAULT NULL, \
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Maps PRIMARY KEY (MapID))";

char sqlite_maps_insert[] = "\
INSERT OR IGNORE INTO Maps (Name, LastPlayed) \
    VALUES ('%s', CURRENT_TIMESTAMP)";

char sqlite_maps_update[] = "\
UPDATE OR IGNORE Maps \
    SET LastPlayed=CURRENT_TIMESTAMP \
    WHERE Name='%s'";

char mysql_maps_upsert[] = "\
INSERT INTO Maps (Name, LastPlayed) \
    VALUES ('%s', CURRENT_TIMESTAMP) \
    ON DUPLICATE KEY UPDATE \
    LastPlayed=CURRENT_TIMESTAMP";

char sql_maps_findid[] = "\
SELECT MapID, Name \
    FROM Maps \
    WHERE Name LIKE '%%%s%%' \
    ORDER BY (Name='%s') DESC, LENGTH(Name) \
    LIMIT 1";



// =====[ MAPCOURSES ]=====

char sqlite_mapcourses_create[] = "\
CREATE TABLE IF NOT EXISTS MapCourses ( \
    MapCourseID INTEGER NOT NULL, \
    MapID INTEGER NOT NULL, \
    Course INTEGER NOT NULL, \
    Created INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_MapCourses PRIMARY KEY (MapCourseID), \
    CONSTRAINT UQ_MapCourses_MapIDCourse UNIQUE (MapID, Course), \
    CONSTRAINT FK_MapCourses_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_mapcourses_create[] = "\
CREATE TABLE IF NOT EXISTS MapCourses ( \
    MapCourseID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, \
    MapID INTEGER UNSIGNED NOT NULL, \
    Course INTEGER UNSIGNED NOT NULL, \
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_MapCourses PRIMARY KEY (MapCourseID), \
    CONSTRAINT UQ_MapCourses_MapIDCourse UNIQUE (MapID, Course), \
    CONSTRAINT FK_MapCourses_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char sqlite_mapcourses_insert[] = "\
INSERT OR IGNORE INTO MapCourses (MapID, Course) \
    VALUES (%d, %d)";

char mysql_mapcourses_insert[] = "\
INSERT IGNORE INTO MapCourses (MapID, Course) \
    VALUES (%d, %d)";



// =====[ TIMES ]=====

char sqlite_times_create[] = "\
CREATE TABLE IF NOT EXISTS Times ( \
    TimeID INTEGER NOT NULL, \
    SteamID32 INTEGER NOT NULL, \
    MapCourseID INTEGER NOT NULL, \
    Mode INTEGER NOT NULL, \
    Style INTEGER NOT NULL, \
    RunTime INTEGER NOT NULL, \
    Teleports INTEGER NOT NULL, \
    Created INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Times PRIMARY KEY (TimeID), \
    CONSTRAINT FK_Times_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) \
    ON UPDATE CASCADE ON DELETE CASCADE, CONSTRAINT FK_Times_MapCourseID \
    FOREIGN KEY (MapCourseID) REFERENCES MapCourses(MapCourseID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_times_create[] = "\
CREATE TABLE IF NOT EXISTS Times ( \
    TimeID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, \
    SteamID32 INTEGER UNSIGNED NOT NULL, \
    MapCourseID INTEGER UNSIGNED NOT NULL, \
    Mode TINYINT UNSIGNED NOT NULL, \
    Style TINYINT UNSIGNED NOT NULL, \
    RunTime INTEGER UNSIGNED NOT NULL, \
    Teleports SMALLINT UNSIGNED NOT NULL, \
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Times PRIMARY KEY (TimeID), \
    CONSTRAINT FK_Times_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) \
    ON UPDATE CASCADE ON DELETE CASCADE, \
    CONSTRAINT FK_Times_MapCourseID FOREIGN KEY (MapCourseID) REFERENCES MapCourses(MapCourseID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char sql_times_insert[] = "\
INSERT INTO Times (SteamID32, MapCourseID, Mode, Style, RunTime, Teleports) \
    SELECT %d, MapCourseID, %d, %d, %d, %d \
    FROM MapCourses \
    WHERE MapID=%d AND Course=%d";



// =====[ JUMPSTATS ]=====

char sqlite_jumpstats_create[] = "\
CREATE TABLE IF NOT EXISTS Jumpstats ( \
    JumpID INTEGER NOT NULL, \
    SteamID32 INTEGER NOT NULL, \
    JumpType INTEGER NOT NULL, \
    Mode INTEGER NOT NULL, \
    Distance INTEGER NOT NULL, \
    IsBlockJump INTEGER NOT NULL, \
    Block INTEGER NOT NULL, \
    Strafes INTEGER NOT NULL, \
    Sync INTEGER NOT NULL, \
    Pre INTEGER NOT NULL, \
    Max INTEGER NOT NULL, \
    Airtime INTEGER NOT NULL, \
    Created INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Jumpstats PRIMARY KEY (JumpID), \
    CONSTRAINT FK_Jumpstats_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_jumpstats_create[] = "\
CREATE TABLE IF NOT EXISTS Jumpstats ( \
    JumpID INTEGER UNSIGNED NOT NULL AUTO_INCREMENT, \
    SteamID32 INTEGER UNSIGNED NOT NULL, \
    JumpType TINYINT UNSIGNED NOT NULL, \
    Mode TINYINT UNSIGNED NOT NULL, \
    Distance INTEGER UNSIGNED NOT NULL, \
    IsBlockJump TINYINT UNSIGNED NOT NULL, \
    Block SMALLINT UNSIGNED NOT NULL, \
    Strafes INTEGER UNSIGNED NOT NULL, \
    Sync INTEGER UNSIGNED NOT NULL, \
    Pre INTEGER UNSIGNED NOT NULL, \
    Max INTEGER UNSIGNED NOT NULL, \
    Airtime INTEGER UNSIGNED NOT NULL, \
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Jumpstats PRIMARY KEY (JumpID), \
    CONSTRAINT FK_Jumpstats_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char sql_jumpstats_insert[] = "\
INSERT INTO Jumpstats (SteamID32, JumpType, Mode, Distance, IsBlockJump, Block, Strafes, Sync, Pre, Max, Airtime) \
    VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d)";

char sql_jumpstats_update[] = "\
UPDATE Jumpstats \
    SET \
        SteamID32=%d, \
        JumpType=%d, \
        Mode=%d, \
        Distance=%d, \
        IsBlockJump=%d, \
        Block=%d, \
        Strafes=%d, \
        Sync=%d, \
        Pre=%d, \
        Max=%d, \
        Airtime=%d \
    WHERE \
        JumpID=%d";

char sql_jumpstats_getrecord[] = "\
SELECT JumpID, Distance, Block \
    FROM \
        Jumpstats \
    WHERE \
        SteamID32=%d AND \
        JumpType=%d AND \
        Mode=%d AND \
        IsBlockJump=%d \
    ORDER BY Block DESC, Distance DESC";

char sql_jumpstats_deleterecord[] = "\
DELETE \
    FROM \
        Jumpstats \
    WHERE \
        JumpID = \
        ( SELECT * FROM ( \
            SELECT JumpID \
                FROM \
                    Jumpstats \
                WHERE \
                    SteamID32=%d AND \
                    JumpType=%d AND \
                    Mode=%d AND \
                    IsBlockJump=%d \
                ORDER BY Block DESC, Distance DESC \
                LIMIT 1 \
			) AS tmp \
        )";

char sql_jumpstats_getpbs[] = "\
SELECT MAX(Distance), Mode, JumpType \
    FROM \
        Jumpstats \
    WHERE \
        SteamID32=%d \
    GROUP BY \
    	Mode, JumpType";

char sql_jumpstats_getblockpbs[] = "\
SELECT MAX(js.Distance), js.Mode, js.JumpType, js.Block \
	FROM \
		Jumpstats js \
	INNER JOIN \
	( \
		SELECT Mode, JumpType, MAX(BLOCK) Block \
			FROM \
				Jumpstats \
			WHERE \
				IsBlockJump=1 AND \
				SteamID32=%d \
			GROUP BY \ 
				Mode, JumpType \
	) pb \
	ON \
		js.Mode=pb.Mode AND \
		js.JumpType=pb.JumpType AND \
		js.Block=pb.Block \
	WHERE \
		js.SteamID32=%d \
	GROUP BY \
		js.Mode, js.JumpType, js.Block";



// =====[ VB POSITIONS ]=====

char sqlite_vbpos_create[] = "\
CREATE TABLE IF NOT EXISTS VBPosition ( \
	SteamID32 INTEGER NOT NULL, \
	MapID INTEGER NOT NULL, \
	X REAL NOT NULL, \
	Y REAL NOT NULL, \
	Z REAL NOT NULL, \
	Course INTEGER NOT NULL, \
	IsStart INTEGER NOT NULL, \
	CONSTRAINT PK_VBPosition PRIMARY KEY (SteamID32, MapID, IsStart), \
    CONSTRAINT FK_VBPosition_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32), \
    CONSTRAINT FK_VBPosition_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_vbpos_create[] = "\
CREATE TABLE IF NOT EXISTS VBPosition ( \
	SteamID32 INTEGER UNSIGNED NOT NULL, \
	MapID INTEGER UNSIGNED NOT NULL, \
	X REAL NOT NULL, \
	Y REAL NOT NULL, \
	Z REAL NOT NULL, \
	Course INTEGER NOT NULL, \
	IsStart INTEGER NOT NULL, \
	CONSTRAINT PK_VBPosition PRIMARY KEY (SteamID32, MapID, IsStart), \
    CONSTRAINT FK_VBPosition_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32), \
    CONSTRAINT FK_VBPosition_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char sql_vbpos_upsert[] = "\
REPLACE INTO VBPosition (SteamID32, MapID, X, Y, Z, Course, IsStart) \
	VALUES (%d, %d, %f, %f, %f, %d, %d)";

char sql_vbpos_get[] = "\
SELECT SteamID32, MapID, Course, IsStart, X, Y, Z \
	FROM \
		VBPosition \
	WHERE \
		SteamID32 = %d AND \
		MapID = %d";



// =====[ START POSITIONS ]=====

char sqlite_startpos_create[] = "\
CREATE TABLE IF NOT EXISTS StartPosition ( \
	SteamID32 INTEGER NOT NULL, \
	MapID INTEGER NOT NULL, \
	X REAL NOT NULL, \
	Y REAL NOT NULL, \
	Z REAL NOT NULL, \
	Angle0 REAL NOT NULL, \
	Angle1 REAL NOT NULL, \
	CONSTRAINT PK_StartPosition PRIMARY KEY (SteamID32, MapID), \
    CONSTRAINT FK_StartPosition_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) \
    CONSTRAINT FK_StartPosition_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char mysql_startpos_create[] = "\
CREATE TABLE IF NOT EXISTS StartPosition ( \
	SteamID32 INTEGER UNSIGNED NOT NULL, \
	MapID INTEGER UNSIGNED NOT NULL, \
	X REAL NOT NULL, \
	Y REAL NOT NULL, \
	Z REAL NOT NULL, \
	Angle0 REAL NOT NULL, \
	Angle1 REAL NOT NULL, \
	CONSTRAINT PK_StartPosition PRIMARY KEY (SteamID32, MapID), \
    CONSTRAINT FK_StartPosition_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32), \
    CONSTRAINT FK_StartPosition_MapID FOREIGN KEY (MapID) REFERENCES Maps(MapID) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char sql_startpos_upsert[] = "\
REPLACE INTO StartPosition (SteamID32, MapID, X, Y, Z, Angle0, Angle1) \
	VALUES (%d, %d, %f, %f, %f, %f, %f)";

char sql_startpos_get[] = "\
SELECT SteamID32, MapID, X, Y, Z, Angle0, Angle1 \
	FROM \
		StartPosition \
	WHERE \
		SteamID32 = %d AND \
		MapID = %d";
