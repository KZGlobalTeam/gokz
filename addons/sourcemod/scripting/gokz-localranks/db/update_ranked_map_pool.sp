/*
	Inserts a list of maps read from a file into the Maps table,
	and updates them to be part of the ranked map pool.
*/



void DB_UpdateRankedMapPool(int client)
{
	if (g_DBType != DatabaseType_SQLite && g_DBType != DatabaseType_MySQL)
	{
		LogError("Unsupported database type, cannot update map pool");
		if (IsValidClient(client))
		{
			// TODO Translation phrases?
			GOKZ_PrintToChat(client, true, "{grey}There was a problem updating the map pool.", LR_CFG_MAP_POOL);
		}
		return;
	}

	File file = OpenFile(LR_CFG_MAP_POOL, "r");
	if (file == null)
	{
		LogError("Failed to load file: \"%s\".", LR_CFG_MAP_POOL);
		if (IsValidClient(client))
		{
			// TODO Translation phrases?
			GOKZ_PrintToChat(client, true, "{grey}There was a problem opening file '%s'.", LR_CFG_MAP_POOL);
		}
		return;
	}

	char map[33];
	int mapsCount = 0;

	Transaction txn = new Transaction();

	// Reset all maps to be unranked
	txn.AddQuery(sql_maps_reset_mappool);

	// Insert/Update maps in gokz-localranks-mappool.cfg to be ranked
	while (file.ReadLine(map, sizeof(map)))
	{
		TrimString(map);
		String_ToLower(map, map, sizeof(map));

		// Ignore blank lines and comments
		if (map[0] == '\0' || map[0] == ';' || (map[0] == '/' && map[1] == '/'))
		{
			continue;
		}

		mapsCount++;

		switch (g_DBType)
		{
			case DatabaseType_SQLite:
			{
				char updateQuery[256];
				gH_DB.Format(updateQuery, sizeof(updateQuery), sqlite_maps_updateranked, 1, map);

				char insertQuery[256];
				gH_DB.Format(insertQuery, sizeof(insertQuery), sqlite_maps_insertranked, 1, map);

				txn.AddQuery(updateQuery);
				txn.AddQuery(insertQuery);
			}
			case DatabaseType_MySQL:
			{
				char query[256];
				gH_DB.Format(query, sizeof(query), mysql_maps_upsertranked, 1, map);

				txn.AddQuery(query);
			}
		}
	}

	delete file;

	if (mapsCount == 0)
	{
		GOKZ_PrintToChatAndLog(client, true, "{darkred}No maps found in file '%s'.", LR_CFG_MAP_POOL);

		if (IsValidClient(client))
		{
			GOKZ_PlayErrorSound(client);
		}

		delete txn;
		return;
	}

	// Pass client user ID (or -1) as data
	int data = -1;
	if (IsValidClient(client))
	{
		data = GetClientUserId(client);
	}

	gH_DB.Execute(txn, DB_TxnSuccess_UpdateRankedMapPool, DB_TxnFailure_Generic, data);
}

public void DB_TxnSuccess_UpdateRankedMapPool(Handle db, int userid, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		LogMessage("The ranked map pool was updated by %L.", client);
		// TODO Translation phrases?
		GOKZ_PrintToChat(client, true, "{grey}The ranked map pool was updated.");
	}
	else
	{
		LogMessage("The ranked map pool was updated.");
	}
}
