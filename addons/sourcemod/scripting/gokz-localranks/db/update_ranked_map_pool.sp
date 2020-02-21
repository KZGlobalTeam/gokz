/*
	Inserts a list of maps read from a file into the Maps table,
	and updates them to be part of the ranked map pool.
*/



void DB_UpdateRankedMapPool(int client)
{
	Handle file = OpenFile(LR_CFG_MAP_POOL, "r");
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
	ArrayList maps = new ArrayList(33, 0);

	// Insert/Update maps in gokz-localranks-mappool.cfg to be ranked
	while (ReadFileLine(file, map, sizeof(map)))
	{
		TrimString(map);
		if (map[0] == '\0' || map[0] == ';' || (map[0] == '/' && map[1] == '/'))
		{
			continue;
		}
		String_ToLower(map, map, sizeof(map));
		maps.PushString(map);
	}
	delete file;

	if (maps.Length == 0)
	{
		if (client == 0)
		{
			PrintToServer("No maps found in file '%s'.", LR_CFG_MAP_POOL);
		}
		else
		{
			// TODO Translation phrases?
			GOKZ_PrintToChat(client, true, "{darkred}No maps found in file '%s'.", LR_CFG_MAP_POOL);
			GOKZ_PlayErrorSound(client);
		}
		return;
	}

	// Create VALUES e.g. (1,'kz_map1'),(1,'kz_map2')
	int valuesSize = maps.Length * 40;
	char[] values = new char[valuesSize];
	maps.GetString(0, map, sizeof(map));
	FormatEx(values, valuesSize, "(1,'%s')", map);
	for (int i = 1; i < maps.Length; i++)
	{
		maps.GetString(i, map, sizeof(map));
		Format(values, valuesSize, "%s,(1,'%s')", values, map);
	}

	// Create query
	int querySize = valuesSize + 128;
	char[] query = new char[querySize];

	Transaction txn = SQL_CreateTransaction();
	// Reset all maps to be unranked
	txn.AddQuery(sql_maps_reset_mappool);

	switch (g_DBType)
	{
		case DatabaseType_SQLite:
		{
			// Create list of maps e.g. 'kz_map1','kz_map2'
			int mapListSize = maps.Length * 36;
			char[] mapList = new char[mapListSize];
			maps.GetString(0, map, sizeof(map));
			FormatEx(mapList, mapListSize, "'%s'", map);
			for (int i = 1; i < maps.Length; i++)
			{
				maps.GetString(i, map, sizeof(map));
				Format(mapList, mapListSize, "%s,'%s'", mapList, map);
			}

			// UPDATE OR IGNORE
			FormatEx(query, querySize, sqlite_maps_updateranked, 1, mapList);
			txn.AddQuery(query);
			// INSERT OR IGNORE
			FormatEx(query, querySize, sqlite_maps_insertranked, values);
			txn.AddQuery(query);
		}
		case DatabaseType_MySQL:
		{
			FormatEx(query, querySize, mysql_maps_upsertranked, values);
			txn.AddQuery(query);
		}
	}

	// Pass client user ID (or -1) as data
	int data = -1;
	if (IsValidClient(client))
	{
		data = GetClientUserId(client);
	}

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_UpdateRankedMapPool, DB_TxnFailure_Generic, data, DBPrio_Low);

	delete maps;
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
