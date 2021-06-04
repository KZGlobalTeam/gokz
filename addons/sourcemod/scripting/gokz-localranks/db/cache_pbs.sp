/*
	Caches the player's personal best times on the map.
*/



void DB_CachePBs(int client, int steamID)
{
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();
	
	// Reset PB exists array
	for (int course = 0; course < GOKZ_MAX_COURSES; course++)
	{
		for (int mode = 0; mode < MODE_COUNT; mode++)
		{
			for (int timeType = 0; timeType < TIMETYPE_COUNT; timeType++)
			{
				gB_PBExistsCache[client][course][mode][timeType] = false;
			}
		}
	}
	
	int mapID = GOKZ_DB_GetCurrentMapID();
	
	// Get Map PBs
	FormatEx(query, sizeof(query), sql_getpbs, steamID, mapID);
	txn.AddQuery(query);
	// Get PRO PBs
	FormatEx(query, sizeof(query), sql_getpbspro, steamID, mapID);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_CachePBs, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_High);
}

public void DB_TxnSuccess_CachePBs(Handle db, int userID, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userID);
	if (client < 1 || client > MaxClients || !IsClientAuthorized(client) || IsFakeClient(client))
	{
		return;
	}
	
	int course, mode;
	
	while (SQL_FetchRow(results[0]))
	{
		course = SQL_FetchInt(results[0], 1);
		mode = SQL_FetchInt(results[0], 2);
		gB_PBExistsCache[client][course][mode][TimeType_Nub] = true;
		gF_PBTimesCache[client][course][mode][TimeType_Nub] = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[0], 0));
	}
	
	while (SQL_FetchRow(results[1]))
	{
		course = SQL_FetchInt(results[1], 1);
		mode = SQL_FetchInt(results[1], 2);
		gB_PBExistsCache[client][course][mode][TimeType_Pro] = true;
		gF_PBTimesCache[client][course][mode][TimeType_Pro] = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[1], 0));
	}
} 