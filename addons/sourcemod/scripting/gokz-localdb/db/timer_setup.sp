
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
		SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SaveTimerSetup, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
	}
	else
	{
		delete data;
		delete txn;
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
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_LoadTimerSetup, DB_TxnFailure_Generic_DataPack, data, DBPrio_Normal);
}

public void DB_TxnSuccess_LoadTimerSetup(Handle db, DataPack data, int numQueries, DBResultSet[] results, any[] queryData)
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
	bool isStart, vbSetup = false;
	float position[3], angles[3];
	
	if (results[0].RowCount > 0 && results[0].FetchRow())
	{
		position[0] = results[0].FetchFloat(TimerSetupDB_GetVBPos_PositionX);
		position[1] = results[0].FetchFloat(TimerSetupDB_GetVBPos_PositionY);
		position[2] = results[0].FetchFloat(TimerSetupDB_GetVBPos_PositionZ);
		course = results[0].FetchInt(TimerSetupDB_GetVBPos_Course);
		isStart = results[0].FetchInt(TimerSetupDB_GetVBPos_IsStart) == 1;
		
		GOKZ_SetVirtualButtonPosition(client, position, course, isStart);
		vbSetup = true;
	}
	
	if (results[0].RowCount > 1 && results[0].FetchRow())
	{
		position[0] = results[0].FetchFloat(TimerSetupDB_GetVBPos_PositionX);
		position[1] = results[0].FetchFloat(TimerSetupDB_GetVBPos_PositionY);
		position[2] = results[0].FetchFloat(TimerSetupDB_GetVBPos_PositionZ);
		course = results[0].FetchInt(TimerSetupDB_GetVBPos_Course);
		isStart = results[0].FetchInt(TimerSetupDB_GetVBPos_IsStart) == 1;
		
		GOKZ_SetVirtualButtonPosition(client, position, course, isStart);
		vbSetup = true;
	}
	
	if (results[1].RowCount > 0 && results[1].FetchRow())
	{
		position[0] = results[1].FetchFloat(TimerSetupDB_GetStartPos_PositionX);
		position[1] = results[1].FetchFloat(TimerSetupDB_GetStartPos_PositionY);
		position[2] = results[1].FetchFloat(TimerSetupDB_GetStartPos_PositionZ);
		angles[0] = results[1].FetchFloat(TimerSetupDB_GetStartPos_Angle0);
		angles[1] = results[1].FetchFloat(TimerSetupDB_GetStartPos_Angle1);
		angles[2] = 0.0;
		
		GOKZ_SetStartPosition(client, StartPositionType_Custom, position, angles);
	}
	
	if (vbSetup)
	{
		GOKZ_LockVirtualButtons(client);
	}
	
	if (doChatMessage)
	{
		GOKZ_PrintToChat(client, true, "%t", "Timer Setup Loaded");
	}
}
