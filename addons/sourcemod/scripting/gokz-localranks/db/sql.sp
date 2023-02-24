/*
	SQL query templates.
*/



// =====[ MAPS ]=====

char sqlite_maps_alter1[] = "\
ALTER TABLE Maps \
    ADD InRankedPool INTEGER NOT NULL DEFAULT '0'";

char mysql_maps_alter1[] = "\
ALTER TABLE Maps \
    ADD InRankedPool TINYINT NOT NULL DEFAULT '0'";

char sqlite_maps_insertranked[] = "\
INSERT OR IGNORE INTO Maps \
    (InRankedPool, Name) \
    VALUES (%d, '%s')";

char sqlite_maps_updateranked[] = "\
UPDATE OR IGNORE Maps \
    SET InRankedPool=%d \
    WHERE Name = '%s'";

char mysql_maps_upsertranked[] = "\
INSERT INTO Maps (InRankedPool, Name) \
    VALUES (%d, '%s') \
    ON DUPLICATE KEY UPDATE \
    InRankedPool=VALUES(InRankedPool)";

char sql_maps_reset_mappool[] = "\
UPDATE Maps \
    SET InRankedPool=0";

char sql_maps_getname[] = "\
SELECT Name \
    FROM Maps \
    WHERE MapID=%d";

char sql_maps_searchbyname[] = "\
SELECT MapID, Name \
    FROM Maps \
    WHERE Name LIKE '%%%s%%' \
    ORDER BY (Name='%s') DESC, LENGTH(Name) \
    LIMIT 1";



// =====[ PLAYERS ]=====

char sql_players_getalias[] = "\
SELECT Alias \
    FROM Players \
    WHERE SteamID32=%d";

char sql_players_searchbyalias[] = "\
SELECT SteamID32, Alias \
    FROM Players \
    WHERE Players.Cheater=0 AND LOWER(Alias) LIKE '%%%s%%' \
    ORDER BY (LOWER(Alias)='%s') DESC, LastPlayed DESC \
    LIMIT 1";



// =====[ MAPCOURSES ]=====

char sql_mapcourses_findid[] = "\
SELECT MapCourseID \
    FROM MapCourses \
    WHERE MapID=%d AND Course=%d";



// =====[ GENERAL ]=====

char sql_getpb[] = "\
SELECT Times.RunTime, Times.Teleports \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    WHERE Times.SteamID32=%d AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d \
    ORDER BY Times.RunTime \
    LIMIT %d";

char sql_getpbpro[] = "\
SELECT Times.RunTime \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    WHERE Times.SteamID32=%d AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0 \
    ORDER BY Times.RunTime \
    LIMIT %d";

char sql_getmaptop[] = "\
SELECT t.TimeID, t.SteamID32, p.Alias, t.RunTime AS PBTime, t.Teleports \
    FROM Times t \
    INNER JOIN MapCourses mc ON mc.MapCourseID=t.MapCourseID \
    INNER JOIN Players p ON p.SteamID32=t.SteamID32 \
    LEFT OUTER JOIN Times t2 ON t2.SteamID32=t.SteamID32 \
    AND t2.MapCourseID=t.MapCourseID AND t2.Mode=t.Mode AND t2.RunTime<t.RunTime \
    WHERE t2.TimeID IS NULL AND p.Cheater=0 AND mc.MapID=%d AND mc.Course=%d AND t.Mode=%d \
    ORDER BY PBTime \
    LIMIT %d";

char sql_getmaptoppro[] = "\
SELECT t.TimeID, t.SteamID32, p.Alias, t.RunTime AS PBTime, t.Teleports \
    FROM Times t \
    INNER JOIN MapCourses mc ON mc.MapCourseID=t.MapCourseID \
    INNER JOIN Players p ON p.SteamID32=t.SteamID32 \
    LEFT OUTER JOIN Times t2 ON t2.SteamID32=t.SteamID32 AND t2.MapCourseID=t.MapCourseID \
    AND t2.Mode=t.Mode AND t2.RunTime<t.RunTime AND t.Teleports=0 AND t2.Teleports=0 \
    WHERE t2.TimeID IS NULL AND p.Cheater=0 AND mc.MapID=%d \
    AND mc.Course=%d AND t.Mode=%d AND t.Teleports=0 \
    ORDER BY PBTime \
    LIMIT %d";

char sql_getwrs[] = "\
SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d \
    GROUP BY MapCourses.Course, Times.Mode";

char sql_getwrspro[] = "\
SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND Times.Teleports=0 \
    GROUP BY MapCourses.Course, Times.Mode";

char sql_getpbs[] = "\
SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    WHERE Times.SteamID32=%d AND MapCourses.MapID=%d \
    GROUP BY MapCourses.Course, Times.Mode";

char sql_getpbspro[] = "\
SELECT MIN(Times.RunTime), MapCourses.Course, Times.Mode \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    WHERE Times.SteamID32=%d AND MapCourses.MapID=%d AND Times.Teleports=0 \
    GROUP BY MapCourses.Course, Times.Mode";

char sql_getmaprank[] = "\
SELECT COUNT(DISTINCT Times.SteamID32) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d \
    AND Times.Mode=%d AND Times.RunTime < \
    (SELECT MIN(Times.RunTime) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND Times.SteamID32=%d AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d) \
    + 1";

char sql_getmaprankpro[] = "\
SELECT COUNT(DISTINCT Times.SteamID32) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d AND MapCourses.Course=%d \
    AND Times.Mode=%d AND Times.Teleports=0 \
    AND Times.RunTime < \
    (SELECT MIN(Times.RunTime) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND Times.SteamID32=%d AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0) \
    + 1";

char sql_getlowestmaprank[] = "\
SELECT COUNT(DISTINCT Times.SteamID32) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d";

char sql_getlowestmaprankpro[] = "\
SELECT COUNT(DISTINCT Times.SteamID32) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0";

char sql_getcount_maincourses[] = "\
SELECT COUNT(*) \
    FROM MapCourses \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    WHERE Maps.InRankedPool=1 AND MapCourses.Course=0";

char sql_getcount_maincoursescompleted[] = "\
SELECT COUNT(DISTINCT Times.MapCourseID) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 \
    AND Times.SteamID32=%d AND Times.Mode=%d";

char sql_getcount_maincoursescompletedpro[] = "\
SELECT COUNT(DISTINCT Times.MapCourseID) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 \
    AND Times.SteamID32=%d AND Times.Mode=%d AND Times.Teleports=0";

char sql_getcount_bonuses[] = "\
SELECT COUNT(*) \
    FROM MapCourses \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    WHERE Maps.InRankedPool=1 AND MapCourses.Course>0";

char sql_getcount_bonusescompleted[] = "\
SELECT COUNT(DISTINCT Times.MapCourseID) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    WHERE Maps.InRankedPool=1 AND MapCourses.Course>0 \
    AND Times.SteamID32=%d AND Times.Mode=%d";

char sql_getcount_bonusescompletedpro[] = "\
SELECT COUNT(DISTINCT Times.MapCourseID) \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    WHERE Maps.InRankedPool=1 AND MapCourses.Course>0 \
    AND Times.SteamID32=%d AND Times.Mode=%d AND Times.Teleports=0";

char sql_gettopplayers[] = "\
SELECT Players.SteamID32, Players.Alias, COUNT(*) AS RecordCount \
    FROM Times \
    INNER JOIN \
    (SELECT Times.MapCourseID, Times.Mode, MIN(Times.RunTime) AS RecordTime \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND Maps.InRankedPool=1 AND MapCourses.Course=0 \
    AND Times.Mode=%d \
    GROUP BY Times.MapCourseID) Records \
    ON Times.MapCourseID=Records.MapCourseID AND Times.Mode=Records.Mode AND Times.RunTime=Records.RecordTime \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    GROUP BY Players.SteamID32, Players.Alias \
    ORDER BY RecordCount DESC \
    LIMIT %d"; // Doesn't include bonuses

char sql_gettopplayerspro[] = "\
SELECT Players.SteamID32, Players.Alias, COUNT(*) AS RecordCount \
    FROM Times \
    INNER JOIN \
    (SELECT Times.MapCourseID, Times.Mode, MIN(Times.RunTime) AS RecordTime \
    FROM Times \
    INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
    INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    WHERE Players.Cheater=0 AND Maps.InRankedPool=1 AND MapCourses.Course=0 \
    AND Times.Mode=%d AND Times.Teleports=0 \
    GROUP BY Times.MapCourseID) Records \
    ON Times.MapCourseID=Records.MapCourseID AND Times.Mode=Records.Mode AND Times.RunTime=Records.RecordTime AND Times.Teleports=0 \
    INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
    GROUP BY Players.SteamID32, Players.Alias \
    ORDER BY RecordCount DESC \
    LIMIT %d"; // Doesn't include bonuses

char sql_getaverage[] = "\
SELECT AVG(PBTime), COUNT(*) \
    FROM \
    (SELECT MIN(Times.RunTime) AS PBTime \
    FROM Times \
    INNER JOIN MapCourses ON Times.MapCourseID=MapCourses.MapCourseID \
    INNER JOIN Players ON Times.SteamID32=Players.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d \
    GROUP BY Times.SteamID32) AS PBTimes";

char sql_getaverage_pro[] = "\
SELECT AVG(PBTime), COUNT(*) \
    FROM \
    (SELECT MIN(Times.RunTime) AS PBTime \
    FROM Times \
    INNER JOIN MapCourses ON Times.MapCourseID=MapCourses.MapCourseID \
    INNER JOIN Players ON Times.SteamID32=Players.SteamID32 \
    WHERE Players.Cheater=0 AND MapCourses.MapID=%d \
    AND MapCourses.Course=%d AND Times.Mode=%d AND Times.Teleports=0 \
    GROUP BY Times.SteamID32) AS PBTimes";

char sql_getrecentrecords[] = "\
SELECT Maps.Name, MapCourses.Course, MapCourses.MapCourseID, Players.Alias, a.RunTime \
    FROM Times AS a \
    INNER JOIN MapCourses ON a.MapCourseID=MapCourses.MapCourseID \
    INNER JOIN Maps ON MapCourses.MapID=Maps.MapID \
    INNER JOIN Players ON a.SteamID32=Players.SteamID32 \
    WHERE Players.Cheater=0 AND Maps.InRankedPool AND a.Mode=%d \
    AND NOT EXISTS \
    (SELECT * \
    FROM Times AS b \
    WHERE a.MapCourseID=b.MapCourseID AND a.Mode=b.Mode \
    AND a.Created>b.Created AND a.RunTime>b.RunTime) \
    ORDER BY a.TimeID DESC \
    LIMIT %d";

char sql_getrecentrecords_pro[] = "\
SELECT Maps.Name, MapCourses.Course, MapCourses.MapCourseID, Players.Alias, a.RunTime \
    FROM Times AS a \
    INNER JOIN MapCourses ON a.MapCourseID=MapCourses.MapCourseID \
    INNER JOIN Maps ON MapCourses.MapID=Maps.MapID \
    INNER JOIN Players ON a.SteamID32=Players.SteamID32 \
    WHERE Players.Cheater=0 AND Maps.InRankedPool AND a.Mode=%d AND a.Teleports=0 \
    AND NOT EXISTS \
    (SELECT * \
    FROM Times AS b \
    WHERE b.Teleports=0 AND a.MapCourseID=b.MapCourseID AND a.Mode=b.Mode \
    AND a.Created>b.Created AND a.RunTime>b.RunTime) \
    ORDER BY a.TimeID DESC \
    LIMIT %d";



// =====[ JUMPSTATS ]=====

char sql_jumpstats_gettop[] = "\
SELECT j.JumpID, p.SteamID32, p.Alias, j.Block, j.Distance, j.Strafes, j.Sync, j.Pre, j.Max, j.Airtime \
	FROM \
		Jumpstats j \
    INNER JOIN \
        Players p ON \
            p.SteamID32=j.SteamID32 AND \
			p.Cheater = 0 \
	INNER JOIN \
		( \
			SELECT j.SteamID32, j.JumpType, j.Mode, j.IsBlockJump, MAX(j.Distance) BestDistance \
			    FROM \
			        Jumpstats j \
			    INNER JOIN \
			        ( \
			            SELECT SteamID32, MAX(Block) AS MaxBlockDist \
			                FROM \
			                    Jumpstats \
			                WHERE \
			                    JumpType = %d AND \
			                    Mode = %d AND \
			                    IsBlockJump = %d \
			                GROUP BY SteamID32 \
			        ) MaxBlock ON \
			            j.SteamID32 = MaxBlock.SteamID32 AND \
			            j.Block = MaxBlock.MaxBlockDist \
			    WHERE \
			        j.JumpType = %d AND \
			        j.Mode = %d AND \
			        j.IsBlockJump = %d \
			    GROUP BY j.SteamID32, j.JumpType, j.Mode, j.IsBlockJump \
		) MaxDist ON \
			j.SteamID32 = MaxDist.SteamID32 AND \
			j.JumpType = MaxDist.JumpType AND \
			j.Mode = MaxDist.Mode AND \
			j.IsBlockJump = MaxDist.IsBlockJump AND \
			j.Distance = MaxDist.BestDistance \
    ORDER BY j.Block DESC, j.Distance DESC \
    LIMIT %d";

char sql_jumpstats_getrecord[] = "\
SELECT JumpID, Distance, Block \
    FROM \
        Jumpstats rec \
    WHERE \
        SteamID32 = %d AND \
        JumpType = %d AND \
        Mode = %d AND \
        IsBlockJump = %d \
    ORDER BY Block DESC, Distance DESC";

char sql_jumpstats_getpbs[] = "\
SELECT b.JumpID, b.JumpType, b.Distance, b.Strafes, b.Sync, b.Pre, b.Max, b.Airtime \
    FROM Jumpstats b \
    INNER JOIN ( \
        SELECT a.SteamID32, a.Mode, a.JumpType, MAX(a.Distance) Distance \
        FROM Jumpstats a \
        WHERE a.SteamID32=%d AND a.Mode=%d AND NOT a.IsBlockJump \
        GROUP BY a.JumpType, a.Mode, a.SteamID32 \
    ) a ON a.JumpType=b.JumpType AND a.Distance=b.Distance \
    WHERE a.SteamID32=b.SteamID32 AND a.Mode=b.Mode AND NOT b.IsBlockJump \
    ORDER BY b.JumpType";

char sql_jumpstats_getblockpbs[] = "\
SELECT c.JumpID, c.JumpType, c.Block, c.Distance, c.Strafes, c.Sync, c.Pre, c.Max, c.Airtime \
    FROM Jumpstats c \
    INNER JOIN ( \
        SELECT a.SteamID32, a.Mode, a.JumpType, a.Block, MAX(b.Distance) Distance \
        FROM Jumpstats b \
        INNER JOIN ( \
            SELECT a.SteamID32, a.Mode, a.JumpType, MAX(a.Block) Block \
            FROM Jumpstats a \
            WHERE a.SteamID32=%d AND a.Mode=%d AND a.IsBlockJump \
            GROUP BY a.JumpType, a.Mode, a.SteamID32 \
        ) a ON a.JumpType=b.JumpType AND a.Block=b.Block \
        WHERE a.SteamID32=b.SteamID32 AND a.Mode=b.Mode AND b.IsBlockJump \
        GROUP BY a.JumpType, a.Mode, a.SteamID32, a.Block \
    ) b ON b.JumpType=c.JumpType AND b.Block=c.Block AND b.Distance=c.Distance \
    WHERE b.SteamID32=c.SteamID32 AND b.Mode=c.Mode AND c.IsBlockJump \
    ORDER BY c.JumpType";
