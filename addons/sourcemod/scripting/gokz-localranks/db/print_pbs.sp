/*
	Prints the player's personal times on a map course and given mode.
*/



void DB_PrintPBs(int client, int targetSteamID, int mapID, int course, int mode)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(course);
	data.WriteCell(mode);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Retrieve Alias of SteamID
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);
	// Retrieve Map Name of MapID
	FormatEx(query, sizeof(query), sql_maps_getname, mapID);
	txn.AddQuery(query);
	// Check for existence of map course with that MapID and Course
	FormatEx(query, sizeof(query), sql_mapcourses_findid, mapID, course);
	txn.AddQuery(query);
	
	// Get PB
	FormatEx(query, sizeof(query), sql_getpb, targetSteamID, mapID, course, mode, 1);
	txn.AddQuery(query);
	// Get Rank
	FormatEx(query, sizeof(query), sql_getmaprank, mapID, course, mode, targetSteamID, mapID, course, mode);
	txn.AddQuery(query);
	// Get Number of Players with Times
	FormatEx(query, sizeof(query), sql_getlowestmaprank, mapID, course, mode);
	txn.AddQuery(query);
	
	// Get PRO PB
	FormatEx(query, sizeof(query), sql_getpbpro, targetSteamID, mapID, course, mode, 1);
	txn.AddQuery(query);
	// Get PRO Rank
	FormatEx(query, sizeof(query), sql_getmaprankpro, mapID, course, mode, targetSteamID, mapID, course, mode);
	txn.AddQuery(query);
	// Get Number of Players with PRO Times
	FormatEx(query, sizeof(query), sql_getlowestmaprankpro, mapID, course, mode);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_PrintPBs, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintPBs(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int course = data.ReadCell();
	int mode = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	char playerName[MAX_NAME_LENGTH], mapName[33];
	
	bool hasPB = false;
	bool hasPBPro = false;
	
	float runTime;
	int teleportsUsed;
	int rank;
	int maxRank;
	
	float runTimePro;
	int rankPro;
	int maxRankPro;
	
	// Get Player Name from results
	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, playerName, sizeof(playerName));
	}
	// Get Map Name from results
	if (SQL_FetchRow(results[1]))
	{
		SQL_FetchString(results[1], 0, mapName, sizeof(mapName));
	}
	if (SQL_GetRowCount(results[2]) == 0)
	{
		if (course == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "Main Course Not Found", mapName);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Bonus Not Found", mapName, course);
		}
		return;
	}
	
	// Get PB info from results
	if (SQL_GetRowCount(results[3]) > 0)
	{
		hasPB = true;
		if (SQL_FetchRow(results[3]))
		{
			runTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[3], 0));
			teleportsUsed = SQL_FetchInt(results[3], 1);
		}
		if (SQL_FetchRow(results[4]))
		{
			rank = SQL_FetchInt(results[4], 0);
		}
		if (SQL_FetchRow(results[5]))
		{
			maxRank = SQL_FetchInt(results[5], 0);
		}
	}
	// Get PB info (Pro) from results
	if (SQL_GetRowCount(results[6]) > 0)
	{
		hasPBPro = true;
		if (SQL_FetchRow(results[6]))
		{
			runTimePro = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[6], 0));
		}
		if (SQL_FetchRow(results[7]))
		{
			rankPro = SQL_FetchInt(results[7], 0);
		}
		if (SQL_FetchRow(results[8]))
		{
			maxRankPro = SQL_FetchInt(results[8], 0);
		}
	}
	
	// Print PB header to chat
	if (course == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "PB Header", playerName, mapName, gC_ModeNamesShort[mode]);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "PB Header (Bonus)", playerName, mapName, course, gC_ModeNamesShort[mode]);
	}
	
	// Print PB times to chat
	if (!hasPB)
	{
		CPrintToChat(client, "%t", "PB Time - No Times");
	}
	else if (!hasPBPro)
	{
		CPrintToChat(client, "%t", "PB Time - NUB", GOKZ_FormatTime(runTime), teleportsUsed, rank, maxRank);
		CPrintToChat(client, "%t", "PB Time - No PRO Time");
	}
	else if (teleportsUsed == 0)
	{  // Their MAP PB has 0 teleports, and is therefore also their PRO PB
		CPrintToChat(client, "%t", "PB Time - NUB and PRO", GOKZ_FormatTime(runTime), rank, maxRank, rankPro, maxRankPro);
	}
	else
	{
		CPrintToChat(client, "%t", "PB Time - NUB", GOKZ_FormatTime(runTime), teleportsUsed, rank, maxRank);
		CPrintToChat(client, "%t", "PB Time - PRO", GOKZ_FormatTime(runTimePro), rankPro, maxRankPro);
	}
}

void DB_PrintPBs_FindMap(int client, int targetSteamID, const char[] mapSearch, int course, int mode)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(targetSteamID);
	data.WriteString(mapSearch);
	data.WriteCell(course);
	data.WriteCell(mode);
	
	DB_FindMap(mapSearch, DB_TxnSuccess_PrintPBs_FindMap, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintPBs_FindMap(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int targetSteamID = data.ReadCell();
	char mapSearch[33];
	data.ReadString(mapSearch, sizeof(mapSearch));
	int course = data.ReadCell();
	int mode = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	// Check if the map course exists in the database
	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Map Not Found", mapSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{  // Result is the MapID
		DB_PrintPBs(client, targetSteamID, SQL_FetchInt(results[0], 0), course, mode);
	}
}

void DB_PrintPBs_FindPlayerAndMap(int client, const char[] playerSearch, const char[] mapSearch, int course, int mode)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(playerSearch);
	data.WriteString(mapSearch);
	data.WriteCell(course);
	data.WriteCell(mode);
	
	DB_FindPlayerAndMap(playerSearch, mapSearch, DB_TxnSuccess_PrintPBs_FindPlayerAndMap, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintPBs_FindPlayerAndMap(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char playerSearch[MAX_NAME_LENGTH];
	data.ReadString(playerSearch, sizeof(playerSearch));
	char mapSearch[33];
	data.ReadString(mapSearch, sizeof(mapSearch));
	int course = data.ReadCell();
	int mode = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", playerSearch);
		return;
	}
	else if (SQL_GetRowCount(results[1]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Map Not Found", mapSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]) && SQL_FetchRow(results[1]))
	{
		DB_PrintPBs(client, SQL_FetchInt(results[0], 0), SQL_FetchInt(results[1], 0), course, mode);
	}
}
