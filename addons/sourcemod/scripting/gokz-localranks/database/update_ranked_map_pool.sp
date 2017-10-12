/*
	Database - Update Ranked Map Pool
	
	Inserts a list of maps read from a file into the Maps table,
	and updates them to be part of the ranked map pool.
*/



void DB_UpdateRankedMapPool(int client)
{
	Handle file = OpenFile(MAP_POOL_CFG_PATH, "r");
	if (file == null)
	{
		LogError("There was a problem opening file: %s", MAP_POOL_CFG_PATH);
		if (IsValidClient(client))
		{
			GOKZ_PrintToChat(client, true, "{grey}There was a problem opening file: %s", MAP_POOL_CFG_PATH);
		}
		return;
	}
	
	char line[33], query[512];
	
	Transaction txn = SQL_CreateTransaction();
	
	// Reset all maps to be unranked
	txn.AddQuery(sql_maps_reset_mappool);
	// Insert/Update maps in mappool.cfg to be ranked
	while (ReadFileLine(file, line, sizeof(line)))
	{
		TrimString(line);
		if (line[0] == '\0' || line[0] == ';' || (line[0] == '/' && line[1] == '/'))
		{
			continue;
		}
		String_ToLower(line, line, sizeof(line));
		switch (g_DBType)
		{
			case DatabaseType_SQLite:
			{
				// UPDATE OR IGNORE
				FormatEx(query, sizeof(query), sqlite_maps_updateranked, 1, line);
				txn.AddQuery(query);
				// INSERT OR IGNORE
				FormatEx(query, sizeof(query), sqlite_maps_insertranked, 1, line);
				txn.AddQuery(query);
			}
			case DatabaseType_MySQL:
			{
				FormatEx(query, sizeof(query), mysql_maps_upsertranked, 1, line);
				txn.AddQuery(query);
			}
		}
	}
	
	int data = -1;
	if (IsValidClient(client))
	{
		data = GetClientUserId(client);
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_UpdateRankedMapPool, DB_TxnFailure_Generic, data, DBPrio_Low);
	
	CloseHandle(file);
}

public void DB_TxnSuccess_UpdateRankedMapPool(Handle db, int userid, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		LogMessage("The ranked map pool was updated by %L.", client);
		GOKZ_PrintToChat(client, true, "{grey}The ranked map pool was updated.");
	}
	else
	{
		LogMessage("The ranked map pool was updated.");
	}
} 