
public void OnLanding_SaveJumpstat(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration, int block, float width, int overlap, int deadair, float deviation, float edge, int releaseW)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	
	// No tiers given for 'Invalid' jumps.
	if (jumpType == JumpType_Invalid || jumpType == JumpType_Fall || jumpType == JumpType_Other
		 || jumpType != JumpType_LadderJump && offset < -JS_MAX_NORMAL_OFFSET
		 || distance > JS_MAX_JUMP_DISTANCE
		 || jumpType == JumpType_LadderJump && distance < JS_MIN_LAJ_BLOCK_DISTANCE
		 || jumpType != JumpType_LadderJump && distance < JS_MIN_BLOCK_DISTANCE)
	{
		return;
	}
	
	char query[1024];
	int steamid = GetSteamAccountID(client);
	
	DataPack data_noblock = new DataPack();
	data_noblock.WriteCell(client);
	data_noblock.WriteCell(steamid);
	data_noblock.WriteCell(jumpType);
	data_noblock.WriteCell(mode);
	data_noblock.WriteCell(RoundToNearest(distance * GOKZ_DB_JS_DISTANCE_PRECISION));
	data_noblock.WriteCell(0);
	data_noblock.WriteCell(strafes);
	data_noblock.WriteCell(RoundToNearest(sync * GOKZ_DB_JS_SYNC_PRECISION));
	data_noblock.WriteCell(RoundToNearest(preSpeed * GOKZ_DB_JS_PRE_PRECISION));
	data_noblock.WriteCell(RoundToNearest(maxSpeed * GOKZ_DB_JS_MAX_PRECISION));
	data_noblock.WriteCell(RoundToNearest(duration * GOKZ_DB_JS_AIRTIME_PRECISION));
	
	Transaction txn_noblock = SQL_CreateTransaction();
	FormatEx(query, sizeof(query), sql_jumpstats_getrecord, steamid, jumpType, mode, 0);
	txn_noblock.AddQuery(query);
	SQL_ExecuteTransaction(gH_DB, txn_noblock, DB_TxnSuccess_LookupJSRecordForSave, DB_TxnFailure_Generic, data_noblock, DBPrio_Low);
	
	if (block > 0)
	{
		DataPack data_block = new DataPack();
		data_block.WriteCell(client);
		data_block.WriteCell(steamid);
		data_block.WriteCell(jumpType);
		data_block.WriteCell(mode);
		data_block.WriteCell(RoundToNearest(distance * GOKZ_DB_JS_DISTANCE_PRECISION));
		data_block.WriteCell(block);
		data_block.WriteCell(strafes);
		data_block.WriteCell(RoundToNearest(sync * GOKZ_DB_JS_SYNC_PRECISION));
		data_block.WriteCell(RoundToNearest(preSpeed * GOKZ_DB_JS_PRE_PRECISION));
		data_block.WriteCell(RoundToNearest(maxSpeed * GOKZ_DB_JS_MAX_PRECISION));
		data_block.WriteCell(RoundToNearest(duration * GOKZ_DB_JS_AIRTIME_PRECISION));
		Transaction txn_block = SQL_CreateTransaction();
		FormatEx(query, sizeof(query), sql_jumpstats_getrecord, steamid, jumpType, mode, 1);
		txn_block.AddQuery(query);
		SQL_ExecuteTransaction(gH_DB, txn_block, DB_TxnSuccess_LookupJSRecordForSave, DB_TxnFailure_Generic, data_block, DBPrio_Low);
	}
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
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SaveJSRecord, DB_TxnFailure_Generic, data, DBPrio_Low);
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
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (block == 0)
	{
		GOKZ_PrintToChat(client, true, "{yellow}%N got a new %s jump record with a %.4f units %s!", client, gC_ModeNamesShort[mode], float(distance) / GOKZ_DB_JS_DISTANCE_PRECISION, gC_JumpTypes[jumpType]);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "{yellow}%N got a new %s block jump record with a %.4f units %s on a %d block!", client, gC_ModeNamesShort[mode], float(distance) / GOKZ_DB_JS_DISTANCE_PRECISION, gC_JumpTypes[jumpType], block);
	}
}

public void DB_DeleteJump(int client, int steamAccountID, int jumpType, int mode, int isBlock)
{
	char query[1024];
	
	FormatEx(query, sizeof(query), sql_jumpstats_deleterecord, steamAccountID, jumpType, mode, isBlock);
	
	Transaction txn = SQL_CreateTransaction();
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_JumpDeleted, DB_TxnFailure_Generic, client, DBPrio_Low);
}

public void DB_TxnSuccess_JumpDeleted(Handle db, int client, int numQueries, Handle[] results, any[] queryData)
{
	GOKZ_PrintToChat(client, true, "{yellow}Jump successfully deleted!");
}
