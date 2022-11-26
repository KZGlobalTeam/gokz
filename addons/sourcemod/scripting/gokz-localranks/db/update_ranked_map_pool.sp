/*
	Inserts a list of maps read from a file into the Maps table,
	and updates them to be part of the ranked map pool.
*/



void DB_UpdateRankedMapPool(int client)
{
	File file = OpenFile(LR_CFG_MAP_POOL, "r");
	if (file == null)
	{
		LogError("Failed to load file: '%s'.", LR_CFG_MAP_POOL);
		if (IsValidClient(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Ranked Map Pool - Error");
		}
		return;
	}

	char map[256];
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
				char updateQuery[512];
				gH_DB.Format(updateQuery, sizeof(updateQuery), sqlite_maps_updateranked, 1, map);

				char insertQuery[512];
				gH_DB.Format(insertQuery, sizeof(insertQuery), sqlite_maps_insertranked, 1, map);

				txn.AddQuery(updateQuery);
				txn.AddQuery(insertQuery);
			}
			case DatabaseType_MySQL:
			{
				char query[512];
				gH_DB.Format(query, sizeof(query), mysql_maps_upsertranked, 1, map);

				txn.AddQuery(query);
			}
		}
	}

	delete file;

	if (mapsCount == 0)
	{
		LogError("No maps found in file: '%s'.", LR_CFG_MAP_POOL);

		if (IsValidClient(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Ranked Map Pool - No Maps In File");
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
		GOKZ_PrintToChat(client, true, "%t", "Ranked Map Pool - Success");
	}
	else
	{
		LogMessage("The ranked map pool was updated.");
	}
}
