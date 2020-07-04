
// ===== [ SAVE TIMER SETUP ] =====

void DB_SaveTimerSetup(int client)
{
	bool txnHasQuery = false;
	int course;
	float position[3], angles[3];
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	int steamid = GetSteamAccountID(client);
	DataPack data = new DataPack();
	
	data.WriteCell(client);
	data.WriteCell(steamid);
	
	char query[1024];
	Transaction txn = SQL_CreateTransaction();
	
	if (GOKZ_GetStartPosition(client, position, angles) == StartPositionType_Custom)
	{
		FormatEx(query, sizeof(query), sql_startpos_upsert, steamid, gI_DBCurrentMapID, position[0], position[1], position[2], angles[0], angles[1]);
		txn.AddQuery(query);
		txnHasQuery = true;
	}
	
	course = GOKZ_GetVirtualButtonPosition(client, position, true);
	if (course != -1)
	{
		FormatEx(query, sizeof(query), sql_vbpos_upsert, steamid, gI_DBCurrentMapID, position[0], position[1], position[2], course, 1);
		txn.AddQuery(query);
		txnHasQuery = true;
	}
	
	course = GOKZ_GetVirtualButtonPosition(client, position, false);
	if (course != -1)
	{
		FormatEx(query, sizeof(query), sql_vbpos_upsert, steamid, gI_DBCurrentMapID, position[0], position[1], position[2], course, 0);
		txn.AddQuery(query);
		txnHasQuery = true;
	}
	
	if (txnHasQuery)
	{
		SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SaveTimerSetup, DB_TxnFailure_Generic, data, DBPrio_Low);
	}
}

public void DB_TxnSuccess_SaveTimerSetup(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = data.ReadCell();
	int steamid = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client) || steamid != GetSteamAccountID(client))
	{
		return;
	}
	
	GOKZ_PrintToChat(client, true, "%t", "Timer Setup Saved");
}



// ===== [ LOAD TIMER SETUP ] =====

void DB_LoadTimerSetup(int client, bool doChatMessage = false)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	int steamid = GetSteamAccountID(client);
	
	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteCell(steamid);
	data.WriteCell(doChatMessage);
	
	char query[1024];
	Transaction txn = SQL_CreateTransaction();
	
	// Virtual Buttons
	FormatEx(query, sizeof(query), sql_vbpos_get, steamid, gI_DBCurrentMapID);
	txn.AddQuery(query);
	
	// Start Position
	FormatEx(query, sizeof(query), sql_startpos_get, steamid, gI_DBCurrentMapID);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_LoadTimerSetup, DB_TxnFailure_Generic, data, DBPrio_Normal);
}

public void DB_TxnSuccess_LoadTimerSetup(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = data.ReadCell();
	int steamid = data.ReadCell();
	bool doChatMessage = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client) || steamid != GetSteamAccountID(client))
	{
		return;
	}
	
	int course;
	bool isStart;
	float position[3], angles[3];
	
	if (SQL_GetRowCount(results[0]) > 0 && SQL_FetchRow(results[0]))
	{
		position[0] = SQL_FetchFloat(results[0], TimerSetupDB_GetVBPos_PositionX);
		position[1] = SQL_FetchFloat(results[0], TimerSetupDB_GetVBPos_PositionY);
		position[2] = SQL_FetchFloat(results[0], TimerSetupDB_GetVBPos_PositionZ);
		course = SQL_FetchInt(results[0], TimerSetupDB_GetVBPos_Course);
		isStart = SQL_FetchInt(results[0], TimerSetupDB_GetVBPos_IsStart) == 1 ? true : false;
		
		GOKZ_SetVirtualButtonPosition(client, position, course, isStart);
	}
	
	if (SQL_GetRowCount(results[0]) > 1 && SQL_FetchRow(results[0]))
	{
		position[0] = SQL_FetchFloat(results[0], TimerSetupDB_GetVBPos_PositionX);
		position[1] = SQL_FetchFloat(results[0], TimerSetupDB_GetVBPos_PositionY);
		position[2] = SQL_FetchFloat(results[0], TimerSetupDB_GetVBPos_PositionZ);
		course = SQL_FetchInt(results[0], TimerSetupDB_GetVBPos_Course);
		isStart = SQL_FetchInt(results[0], TimerSetupDB_GetVBPos_IsStart) == 1 ? true : false;
		
		GOKZ_SetVirtualButtonPosition(client, position, course, isStart);
	}
	
	if (SQL_GetRowCount(results[1]) > 0 && SQL_FetchRow(results[1]))
	{
		position[0] = SQL_FetchFloat(results[1], TimerSetupDB_GetStartPos_PositionX);
		position[1] = SQL_FetchFloat(results[1], TimerSetupDB_GetStartPos_PositionY);
		position[2] = SQL_FetchFloat(results[1], TimerSetupDB_GetStartPos_PositionZ);
		angles[0] = SQL_FetchFloat(results[1], TimerSetupDB_GetStartPos_Angle0);
		angles[1] = SQL_FetchFloat(results[1], TimerSetupDB_GetStartPos_Angle1);
		angles[2] = 0.0;
		
		GOKZ_SetStartPosition(client, StartPositionType_Custom, position, angles);
	}
	
	if (doChatMessage)
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Setup Loaded");
	}
}
