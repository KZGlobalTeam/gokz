/*
	Caches the player's personal best jumpstats.
*/



void DB_CacheJSPBs(int client, int steamID)
{
	ClearCache(client);
	
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();
	
	FormatEx(query, sizeof(query), sql_jumpstats_getpbs, steamID);
	txn.AddQuery(query);
	
	FormatEx(query, sizeof(query), sql_jumpstats_getblockpbs, steamID, steamID);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_CacheJSPBs, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_High);
}

public void DB_TxnSuccess_CacheJSPBs(Handle db, int userID, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userID);
	if (client < 1 || client > MaxClients || !IsClientAuthorized(client) || IsFakeClient(client))
	{
		return;
	}
	
	int distance, mode, jumpType, block;
	
	while (SQL_FetchRow(results[0]))
	{
		distance = SQL_FetchInt(results[0], 0);
		mode = SQL_FetchInt(results[0], 1);
		jumpType = SQL_FetchInt(results[0], 2);
		
		gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_Distance] = block;
	}
	
	while (SQL_FetchRow(results[1]))
	{
		distance = SQL_FetchInt(results[1], 0);
		mode = SQL_FetchInt(results[1], 1);
		jumpType = SQL_FetchInt(results[1], 2);
		block = SQL_FetchInt(results[1], 3);
		
		gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_BlockDistance] = distance;
		gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_Block] = block;
	}
}

static void ClearCache(int client)
{
	for (int mode = 0; mode < MODE_COUNT; mode += 1)
	{
		for (int type = 0; type < JUMPTYPE_COUNT; type += 1)
		{
			for (int cache = 0; cache < JUMPSTATDB_CACHE_COUNT; cache += 1)
			{
				gI_PBJSCache[client][mode][type][cache] = 0;
			}
		}
	}
} 