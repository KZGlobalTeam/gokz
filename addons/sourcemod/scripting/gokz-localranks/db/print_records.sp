/*
	Prints the record times on a map course and given mode.
*/



void DB_PrintRecords(int client, int mapID, int course, int mode)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(course);
	data.WriteCell(mode);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Retrieve Map Name of MapID
	FormatEx(query, sizeof(query), sql_maps_getname, mapID);
	txn.AddQuery(query);
	// Check for existence of map course with that MapID and Course
	FormatEx(query, sizeof(query), sql_mapcourses_findid, mapID, course);
	txn.AddQuery(query);
	
	// Get Map WR
	FormatEx(query, sizeof(query), sql_getmaptop, mapID, course, mode, 1);
	txn.AddQuery(query);
	// Get PRO WR
	FormatEx(query, sizeof(query), sql_getmaptoppro, mapID, course, mode, 1);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_PrintRecords, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintRecords(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
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
	
	char mapName[33];
	
	bool mapHasRecord = false;
	bool mapHasRecordPro = false;
	
	char recordHolder[33];
	float runTime;
	int teleportsUsed;
	
	char recordHolderPro[33];
	float runTimePro;
	
	// Get Map Name from results
	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, mapName, sizeof(mapName));
	}
	// Check if the map course exists in the database
	if (SQL_GetRowCount(results[1]) == 0)
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
	
	// Get WR info from results
	if (SQL_GetRowCount(results[2]) > 0)
	{
		mapHasRecord = true;
		if (SQL_FetchRow(results[2]))
		{
			SQL_FetchString(results[2], 1, recordHolder, sizeof(recordHolder));
			runTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[2], 2));
			teleportsUsed = SQL_FetchInt(results[2], 3);
		}
	}
	// Get Pro WR info from results
	if (SQL_GetRowCount(results[3]) > 0)
	{
		mapHasRecordPro = true;
		if (SQL_FetchRow(results[3]))
		{
			SQL_FetchString(results[3], 1, recordHolderPro, sizeof(recordHolderPro));
			runTimePro = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[3], 2));
		}
	}
	
	// Print WR header to chat
	if (course == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "WR Header", mapName, gC_ModeNamesShort[mode]);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "WR Header (Bonus)", mapName, course, gC_ModeNamesShort[mode]);
	}
	
	// Print WR times to chat
	if (!mapHasRecord)
	{
		CPrintToChat(client, "%t", "No Times Found");
	}
	else if (!mapHasRecordPro)
	{
		CPrintToChat(client, "%t", "WR Time - NUB", GOKZ_FormatTime(runTime), teleportsUsed, recordHolder);
		CPrintToChat(client, "%t", "WR Time - No PRO Time");
	}
	else if (teleportsUsed == 0)
	{
		CPrintToChat(client, "%t", "WR Time - NUB and PRO", GOKZ_FormatTime(runTimePro), recordHolderPro);
	}
	else
	{
		CPrintToChat(client, "%t", "WR Time - NUB", GOKZ_FormatTime(runTime), teleportsUsed, recordHolder);
		CPrintToChat(client, "%t", "WR Time - PRO", GOKZ_FormatTime(runTimePro), recordHolderPro);
	}
}

void DB_PrintRecords_FindMap(int client, const char[] mapSearch, int course, int mode)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(mapSearch);
	data.WriteCell(course);
	data.WriteCell(mode);
	
	DB_FindMap(mapSearch, DB_TxnSuccess_PrintRecords_FindMap, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintRecords_FindMap(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
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
		GOKZ_PrintToChat(client, true, "%t", "Map Not Found", mapSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{  // Result is the MapID
		DB_PrintRecords(client, SQL_FetchInt(results[0], 0), course, mode);
		if (gB_GOKZGlobal)
		{
			char map[33];
			SQL_FetchString(results[0], 1, map, sizeof(map));
			GOKZ_GL_PrintRecords(client, map, course, GOKZ_GetCoreOption(client, Option_Mode));
		}
	}
} 