/*
	Processes a newly submitted time, determining if the player beat their
	personal best and if they beat the map course and mode's record time.
*/



void DB_ProcessNewTime(int client, int steamID, int mapID, int course, int mode, int style, int runTimeMS, int teleportsUsed)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(steamID);
	data.WriteCell(mapID);
	data.WriteCell(course);
	data.WriteCell(mode);
	data.WriteCell(style);
	data.WriteCell(runTimeMS);
	data.WriteCell(teleportsUsed);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Get Top 2 PBs
	FormatEx(query, sizeof(query), sql_getpb, steamID, mapID, course, mode, 2);
	txn.AddQuery(query);
	// Get Rank
	FormatEx(query, sizeof(query), sql_getmaprank, mapID, course, mode, steamID, mapID, course, mode);
	txn.AddQuery(query);
	// Get Number of Players with Times
	FormatEx(query, sizeof(query), sql_getlowestmaprank, mapID, course, mode);
	txn.AddQuery(query);
	
	if (teleportsUsed == 0)
	{
		// Get Top 2 PRO PBs
		FormatEx(query, sizeof(query), sql_getpbpro, steamID, mapID, course, mode, 2);
		txn.AddQuery(query);
		// Get PRO Rank
		FormatEx(query, sizeof(query), sql_getmaprankpro, mapID, course, mode, steamID, mapID, course, mode);
		txn.AddQuery(query);
		// Get Number of Players with PRO Times
		FormatEx(query, sizeof(query), sql_getlowestmaprankpro, mapID, course, mode);
		txn.AddQuery(query);
	}
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_ProcessTimerEnd, DB_TxnFailure_Generic_DataPack, data, DBPrio_Normal);
}

public void DB_TxnSuccess_ProcessTimerEnd(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int steamID = data.ReadCell();
	int mapID = data.ReadCell();
	int course = data.ReadCell();
	int mode = data.ReadCell();
	int style = data.ReadCell();
	int runTimeMS = data.ReadCell();
	int teleportsUsed = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	bool firstTime = SQL_GetRowCount(results[0]) == 1;
	int pbDiff = 0;
	int rank = -1;
	int maxRank = -1;
	if (!firstTime)
	{
		SQL_FetchRow(results[0]);
		int pb = SQL_FetchInt(results[0], 0);
		if (runTimeMS == pb) // New time is new PB
		{
			SQL_FetchRow(results[0]);
			int oldPB = SQL_FetchInt(results[0], 0);
			pbDiff = runTimeMS - oldPB;
		}
		else // Didn't beat PB
		{
			pbDiff = runTimeMS - pb;
		}
	}
	// Get NUB Rank
	SQL_FetchRow(results[1]);
	rank = SQL_FetchInt(results[1], 0);
	SQL_FetchRow(results[2]);
	maxRank = SQL_FetchInt(results[2], 0);
	
	// Repeat for PRO Runs
	bool firstTimePro = false;
	int pbDiffPro = 0;
	int rankPro = -1;
	int maxRankPro = -1;
	if (teleportsUsed == 0)
	{
		firstTimePro = SQL_GetRowCount(results[3]) == 1;
		if (!firstTimePro)
		{
			SQL_FetchRow(results[3]);
			int pb = SQL_FetchInt(results[3], 0);
			if (runTimeMS == pb) // New time is new PB
			{
				SQL_FetchRow(results[3]);
				int oldPB = SQL_FetchInt(results[3], 0);
				pbDiffPro = runTimeMS - oldPB;
			}
			else // Didn't beat PB
			{
				pbDiffPro = runTimeMS - pb;
			}
		}
		// Get PRO Rank
		SQL_FetchRow(results[4]);
		rankPro = SQL_FetchInt(results[4], 0);
		SQL_FetchRow(results[5]);
		maxRankPro = SQL_FetchInt(results[5], 0);
	}
	
	// Call OnTimeProcessed forward
	Call_OnTimeProcessed(
		client, 
		steamID, 
		mapID, 
		course, 
		mode, 
		style, 
		GOKZ_DB_TimeIntToFloat(runTimeMS), 
		teleportsUsed, 
		firstTime, 
		GOKZ_DB_TimeIntToFloat(pbDiff), 
		rank, 
		maxRank, 
		firstTimePro, 
		GOKZ_DB_TimeIntToFloat(pbDiffPro), 
		rankPro, 
		maxRankPro);
	
	// Call OnNewRecord forward
	bool newWR = (firstTime || pbDiff < 0) && rank == 1;
	bool newWRPro = (firstTimePro || pbDiffPro < 0) && rankPro == 1;
	if (newWR && newWRPro)
	{
		Call_OnNewRecord(client, steamID, mapID, course, mode, style, RecordType_NubAndPro);
	}
	else if (newWR)
	{
		Call_OnNewRecord(client, steamID, mapID, course, mode, style, RecordType_Nub);
	}
	else if (newWRPro)
	{
		Call_OnNewRecord(client, steamID, mapID, course, mode, style, RecordType_Pro);
	}
} 