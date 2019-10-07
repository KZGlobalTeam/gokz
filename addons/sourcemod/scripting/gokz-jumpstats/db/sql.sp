/*
	SQL query templates.
*/



char sqlite_jumpstats_create[] = "\
CREATE TABLE IF NOT EXISTS Jumpstats ( \
    JumpID INTEGER NOT NULL, \
    SteamID32 INTEGER NOT NULL, \
    JumpType INTEGER NOT NULL, \
    Mode INTEGER NOT NULL, \
    Distance INTEGER NOT NULL, \
    IsBlockJump INTEGER NOT NULL, \
    Block INTEGER NOT NULL, \
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
    Created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, \
    CONSTRAINT PK_Jumpstats PRIMARY KEY (JumpID), \
    CONSTRAINT FK_Jumpstats_SteamID32 FOREIGN KEY (SteamID32) REFERENCES Players(SteamID32) \
    ON UPDATE CASCADE ON DELETE CASCADE)";

char sql_jumpstats_getrecord[] = "\
SELECT JumpID, Distance, Block \
    FROM \
        Jumpstats \
    WHERE \
        SteamID32 = %d AND \
        JumpType = %d AND \
        Mode = %d AND \
        IsBlockJump = %d";

char sql_jumpstats_insert[] = "\
INSERT INTO Jumpstats (SteamID32, JumpType, Mode, Distance, IsBlockJump, Block) \
    VALUES (%d, %d, %d, %d, %d, %d)";

char sql_jumpstats_update[] = "\
UPDATE Jumpstats \
    SET \
        SteamID32 = %d, \
        JumpType = %d, \
        Mode = %d, \
        Distance = %d, \
        IsBlockJump = %d, \
        Block = %d \
    WHERE \
        JumpID = %d";

char sql_players_searchbyalias[] = "\
SELECT SteamID32, Alias \
    FROM Players \
    WHERE Players.Cheater=0 AND LOWER(Alias) LIKE '%%%s%%' \
    ORDER BY (LOWER(Alias)='%s') DESC, LastPlayed DESC \
    LIMIT 1";
    
char sql_jumpstats_gettop[] = "\
SELECT p.Alias, j.Block, j.Distance \
    FROM \
        Jumpstats j \
    INNER JOIN \
        Players p ON \
            p.SteamID32=j.SteamID32 \
    WHERE \
        p.Cheater = 0 AND \
        j.JumpType = %d AND \
        j.Mode = %d AND \
        j.IsBlockJump = %d \
    ORDER BY j.Block DESC, j.Distance DESC \
    LIMIT %d";
