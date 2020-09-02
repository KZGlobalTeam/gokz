/*
	Prints the player's personal best jumps.
*/



void DisplayJumpstatRecord(int client, int jumpType, char[] jumper = "")
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	
	int steamid;
	char alias[33];
	if (StrEqual(jumper, ""))
	{
		steamid = GetSteamAccountID(client);
		FormatEx(alias, sizeof(alias), "%N", client);
		
		DB_JS_OpenPlayerRecord(client, steamid, alias, jumpType, mode, 0);
		DB_JS_OpenPlayerRecord(client, steamid, alias, jumpType, mode, 1);
	}
	else
	{
		DataPack data = new DataPack();
		data.WriteCell(client);
		data.WriteCell(jumpType);
		data.WriteCell(mode);
		data.WriteString(jumper);
		
		DB_FindPlayer(jumper, DB_JS_TxnSuccess_LookupPlayer, data);
	}
}

public void DB_JS_TxnSuccess_LookupPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	char jumper[MAX_NAME_LENGTH];
	
	data.Reset();
	int client = data.ReadCell();
	int jumpType = data.ReadCell();
	int mode = data.ReadCell();
	data.ReadString(jumper, sizeof(jumper));
	delete data;
	
	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", jumper);
		return;
	}
	
	char alias[33];
	SQL_FetchRow(results[0]);
	int steamid = SQL_FetchInt(results[0], JumpstatDB_FindPlayer_SteamID32);
	SQL_FetchString(results[0], JumpstatDB_FindPlayer_Alias, alias, sizeof(alias));
	
	DB_JS_OpenPlayerRecord(client, steamid, alias, jumpType, mode, 0);
	DB_JS_OpenPlayerRecord(client, steamid, alias, jumpType, mode, 1);
}

void DB_JS_OpenPlayerRecord(int client, int steamid, char[] alias, int jumpType, int mode, int block)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteString(alias);
	data.WriteCell(jumpType);
	data.WriteCell(mode);
	
	Transaction txn = SQL_CreateTransaction();
	FormatEx(query, sizeof(query), sql_jumpstats_getrecord, steamid, jumpType, mode, block);
	txn.AddQuery(query);
	SQL_ExecuteTransaction(gH_DB, txn, DB_JS_TxnSuccess_OpenPlayerRecord, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_JS_TxnSuccess_OpenPlayerRecord(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	char alias[33];
	data.Reset();
	int client = data.ReadCell();
	data.ReadString(alias, sizeof(alias));
	int jumpType = data.ReadCell();
	int mode = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Jumpstats Found");
		return;
	}
	
	SQL_FetchRow(results[0]);
	float distance = float(SQL_FetchInt(results[0], JumpstatDB_Lookup_Distance)) / 10000;
	int block = SQL_FetchInt(results[0], JumpstatDB_Lookup_Block);
	
	if (block == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Jump Record", gC_ModeNamesShort[mode], gC_JumpTypes[jumpType], alias, distance);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "Block Jump Record", gC_ModeNamesShort[mode], gC_JumpTypes[jumpType], alias, block, distance);
	}
}
