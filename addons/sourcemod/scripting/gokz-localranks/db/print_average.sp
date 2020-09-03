/*
	Gets the average personal best time of a course.
*/



void DB_PrintAverage(int client, int mapID, int course, int mode)
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
	// Get Average PB Time
	FormatEx(query, sizeof(query), sql_getaverage, mapID, course, mode);
	txn.AddQuery(query);
	// Get Average PRO PB Time
	FormatEx(query, sizeof(query), sql_getaverage_pro, mapID, course, mode);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_PrintAverage, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintAverage(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
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
	int mapCompletions, mapCompletionsPro;
	float averageTime, averageTimePro;
	
	// Get Map Name from results
	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, mapName, sizeof(mapName));
	}
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
	
	// Get number of completions and average time
	if (SQL_FetchRow(results[2]))
	{
		mapCompletions = SQL_FetchInt(results[2], 1);
		if (mapCompletions > 0)
		{
			averageTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[2], 0));
		}
	}
	
	// Get number of completions and average time (PRO)
	if (SQL_FetchRow(results[3]))
	{
		mapCompletionsPro = SQL_FetchInt(results[3], 1);
		if (mapCompletions > 0)
		{
			averageTimePro = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[3], 0));
		}
	}
	
	// Print average time header to chat
	if (course == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Average Time Header", mapName, gC_ModeNamesShort[mode]);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Average Time Header (Bonus)", mapName, course, gC_ModeNamesShort[mode]);
	}
	
	if (mapCompletions == 0)
	{
		CPrintToChat(client, "%t", "No Times Found");
	}
	else if (mapCompletionsPro == 0)
	{
		CPrintToChat(client, "%t, %t", 
			"Average Time - NUB", GOKZ_FormatTime(averageTime), mapCompletions, 
			"Average Time - No PRO Time");
	}
	else
	{
		CPrintToChat(client, "%t, %t", 
			"Average Time - NUB", GOKZ_FormatTime(averageTime), mapCompletions, 
			"Average Time - PRO", GOKZ_FormatTime(averageTimePro), mapCompletionsPro);
	}
}

void DB_PrintAverage_FindMap(int client, const char[] mapSearch, int course, int mode)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(mapSearch);
	data.WriteCell(course);
	data.WriteCell(mode);
	
	DB_FindMap(mapSearch, DB_TxnSuccess_PrintAverage_FindMap, data, DBPrio_Low);
}

public void DB_TxnSuccess_PrintAverage_FindMap(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
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
		DB_PrintAverage(client, SQL_FetchInt(results[0], 0), course, mode);
	}
} 