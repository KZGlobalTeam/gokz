/*
	Inserts or updates the player's jumpstat into the database.
*/



public void OnLanding_SaveJumpstat(Jump jump)
{
	int mode = GOKZ_GetCoreOption(jump.jumper, Option_Mode);
	
	// No tiers given for 'Invalid' jumps.
	if (jump.type == JumpType_Invalid || jump.type == JumpType_FullInvalid
		 || jump.type == JumpType_Fall || jump.type == JumpType_Other
		 || jump.type != JumpType_LadderJump && jump.offset < -JS_OFFSET_EPSILON
		 || jump.distance > JS_MAX_JUMP_DISTANCE
		 || jump.type == JumpType_LadderJump && jump.distance < JS_MIN_LAJ_BLOCK_DISTANCE
		 || jump.type != JumpType_LadderJump && jump.distance < JS_MIN_BLOCK_DISTANCE)
	{
		return;
	}
	
	char query[1024];
	DataPack data;
	int steamid = GetSteamAccountID(jump.jumper);
	int int_dist = RoundToNearest(jump.distance * GOKZ_DB_JS_DISTANCE_PRECISION);
	
	// Non-block
	if (gI_PBJSCache[jump.jumper][mode][jump.type][JumpstatDB_Cache_Distance] == 0
		 || int_dist > gI_PBJSCache[jump.jumper][mode][jump.type][JumpstatDB_Cache_Distance])
	{
		data = JSRecord_FillDataPack(jump, steamid, mode, false);
		Transaction txn_noblock = SQL_CreateTransaction();
		FormatEx(query, sizeof(query), sql_jumpstats_getrecord, steamid, jump.type, mode, 0);
		txn_noblock.AddQuery(query);
		SQL_ExecuteTransaction(gH_DB, txn_noblock, DB_TxnSuccess_LookupJSRecordForSave, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
	}
	
	// Block
	if (jump.block > 0
		 && (gI_PBJSCache[jump.jumper][mode][jump.type][JumpstatDB_Cache_Block] == 0
			 || (jump.block > gI_PBJSCache[jump.jumper][mode][jump.type][JumpstatDB_Cache_Block]
				 || jump.block == gI_PBJSCache[jump.jumper][mode][jump.type][JumpstatDB_Cache_Block]
				 && int_dist > gI_PBJSCache[jump.jumper][mode][jump.type][JumpstatDB_Cache_BlockDistance])))
	{
		data = JSRecord_FillDataPack(jump, steamid, mode, true);
		Transaction txn_block = SQL_CreateTransaction();
		FormatEx(query, sizeof(query), sql_jumpstats_getrecord, steamid, jump.type, mode, 1);
		txn_block.AddQuery(query);
		SQL_ExecuteTransaction(gH_DB, txn_block, DB_TxnSuccess_LookupJSRecordForSave, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
	}
}

static DataPack JSRecord_FillDataPack(Jump jump, int steamid, int mode, bool blockJump)
{
	DataPack data = new DataPack();
	data.WriteCell(jump.jumper);
	data.WriteCell(steamid);
	data.WriteCell(jump.type);
	data.WriteCell(mode);
	data.WriteCell(RoundToNearest(jump.distance * GOKZ_DB_JS_DISTANCE_PRECISION));
	data.WriteCell(blockJump ? jump.block : 0);
	data.WriteCell(jump.strafes);
	data.WriteCell(RoundToNearest(jump.sync * GOKZ_DB_JS_SYNC_PRECISION));
	data.WriteCell(RoundToNearest(jump.preSpeed * GOKZ_DB_JS_PRE_PRECISION));
	data.WriteCell(RoundToNearest(jump.maxSpeed * GOKZ_DB_JS_MAX_PRECISION));
	data.WriteCell(RoundToNearest(jump.duration * GetTickInterval() * GOKZ_DB_JS_AIRTIME_PRECISION));
	return data;
}

public void DB_TxnSuccess_LookupJSRecordForSave(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = data.ReadCell();
	int steamid = data.ReadCell();
	int jumpType = data.ReadCell();
	int mode = data.ReadCell();
	int distance = data.ReadCell();
	int block = data.ReadCell();
	int strafes = data.ReadCell();
	int sync = data.ReadCell();
	int pre = data.ReadCell();
	int max = data.ReadCell();
	int airtime = data.ReadCell();
	
	if (!IsValidClient(client))
	{
		delete data;
		return;
	}
	
	char query[1024];
	int rows = SQL_GetRowCount(results[0]);
	if (rows == 0)
	{
		FormatEx(query, sizeof(query), sql_jumpstats_insert, steamid, jumpType, mode, distance, block > 0, block, strafes, sync, pre, max, airtime);
	}
	else
	{
		SQL_FetchRow(results[0]);
		int rec_distance = SQL_FetchInt(results[0], JumpstatDB_Lookup_Distance);
		int rec_block = SQL_FetchInt(results[0], JumpstatDB_Lookup_Block);
		
		if (rec_block == 0)
		{
			gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_Distance] = rec_distance;
		}
		else
		{
			gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_Block] = rec_block;
			gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_BlockDistance] = rec_distance;
		}
		
		if (block < rec_block || block == rec_block && distance < rec_distance)
		{
			delete data;
			return;
		}
		
		if (rows < GOKZ_DB_JS_MAX_JUMPS_PER_PLAYER)
		{
			FormatEx(query, sizeof(query), sql_jumpstats_insert, steamid, jumpType, mode, distance, block > 0, block, strafes, sync, pre, max, airtime);
		}
		else
		{
			for (int i = 1; i < GOKZ_DB_JS_MAX_JUMPS_PER_PLAYER; i++)
			{
				SQL_FetchRow(results[0]);
			}
			int min_rec_id = SQL_FetchInt(results[0], JumpstatDB_Lookup_JumpID);
			FormatEx(query, sizeof(query), sql_jumpstats_update, steamid, jumpType, mode, distance, block > 0, block, strafes, sync, pre, max, airtime, min_rec_id);
		}
		
	}
	
	Transaction txn = SQL_CreateTransaction();
	txn.AddQuery(query);
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SaveJSRecord, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_SaveJSRecord(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = data.ReadCell();
	data.ReadCell();
	int jumpType = data.ReadCell();
	int mode = data.ReadCell();
	int distance = data.ReadCell();
	int block = data.ReadCell();
	int strafes = data.ReadCell();
	int sync = data.ReadCell();
	int pre = data.ReadCell();
	int max = data.ReadCell();
	int airtime = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client) || GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster) == JSToggleOption_Disabled)
	{
		return;
	}
	
	float distanceFloat = float(distance) / GOKZ_DB_JS_DISTANCE_PRECISION;
	float syncFloat = float(sync) / GOKZ_DB_JS_SYNC_PRECISION;
	float preFloat = float(pre) / GOKZ_DB_JS_PRE_PRECISION;
	float maxFloat = float(max) / GOKZ_DB_JS_MAX_PRECISION;
	
	if (block == 0)
	{
		gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_Distance] = distance;
		GOKZ_PrintToChat(client, true, "%t", "Jump Record", 
			client, 
			gC_JumpTypes[jumpType], 
			distanceFloat, 
			gC_ModeNamesShort[mode]);
	}
	else
	{
		gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_Block] = block;
		gI_PBJSCache[client][mode][jumpType][JumpstatDB_Cache_BlockDistance] = distance;
		GOKZ_PrintToChat(client, true, "%t", "Block Jump Record", 
			client, 
			block, 
			gC_JumpTypes[jumpType], 
			distanceFloat, 
			gC_ModeNamesShort[mode], 
			block);
	}
	
	Call_OnJumpstatPB(client, jumpType, mode, distanceFloat, block, strafes, syncFloat, preFloat, maxFloat, airtime);
}

public void DB_DeleteBestJump(int client, int steamAccountID, int jumpType, int mode, int isBlock)
{
	DataPack data = new DataPack();
	data.WriteCell(client == 0 ? -1 : GetClientUserId(client)); // -1 if called from server console
	data.WriteCell(steamAccountID);
	data.WriteCell(jumpType);
	data.WriteCell(mode);
	data.WriteCell(isBlock);
	
	char query[1024];
	
	FormatEx(query, sizeof(query), sql_jumpstats_deleterecord, steamAccountID, jumpType, mode, isBlock);
	
	Transaction txn = SQL_CreateTransaction();
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_BestJumpDeleted, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_BestJumpDeleted(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	char blockString[16] = "";
	
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int steamAccountID = data.ReadCell();
	int jumpType = data.ReadCell();
	int mode = data.ReadCell();
	bool isBlock = data.ReadCell() == 1;
	delete data;
	
	if (isBlock)
	{
		FormatEx(blockString, sizeof(blockString), "%T ", "Block", client);
	}
	
	ClearCache(client);
	
	GOKZ_PrintToChatAndLog(client, true, "%t", "Best Jump Deleted", 
		gC_ModeNames[mode], 
		blockString, 
		gC_JumpTypes[jumpType],
		steamAccountID & 1,
		steamAccountID >> 1);
}

public void DB_DeleteAllJumps(int client, int steamAccountID)
{
	DataPack data = new DataPack();
	data.WriteCell(client == 0 ? -1 : GetClientUserId(client)); // -1 if called from server console
	data.WriteCell(steamAccountID);
	
	char query[1024];
	
	FormatEx(query, sizeof(query), sql_jumpstats_deleteallrecords, steamAccountID);
	
	Transaction txn = SQL_CreateTransaction();
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_AllJumpsDeleted, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_AllJumpsDeleted(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int steamAccountID = data.ReadCell();
	delete data;
	
	ClearCache(client);
	
	GOKZ_PrintToChatAndLog(client, true, "%t", "All Jumps Deleted", 
		steamAccountID & 1,
		steamAccountID >> 1);
}

public void DB_DeleteJump(int client, int jumpID)
{
	DataPack data = new DataPack();
	data.WriteCell(client == 0 ? -1 : GetClientUserId(client)); // -1 if called from server console
	data.WriteCell(jumpID);

	char query[1024];
	FormatEx(query, sizeof(query), sql_jumpstats_deletejump, jumpID);

	Transaction txn = SQL_CreateTransaction();
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_JumpDeleted, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_JumpDeleted(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int jumpID = data.ReadCell();
	delete data;

	GOKZ_PrintToChatAndLog(client, true, "%t", "Jump Deleted", 
		jumpID);
}
