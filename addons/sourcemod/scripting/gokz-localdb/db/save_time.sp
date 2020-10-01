/*
	Inserts the player's time into the database.
*/



void DB_SaveTime(int client, int course, int mode, int style, float runTime, int teleportsUsed)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	char query[1024];
	int steamID = GetSteamAccountID(client);
	int mapID = GOKZ_DB_GetCurrentMapID();
	int runTimeMS = GOKZ_DB_TimeFloatToInt(runTime);
	
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
	
	// Save runTime to DB
	FormatEx(query, sizeof(query), sql_times_insert, steamID, mode, style, runTimeMS, teleportsUsed, mapID, course);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SaveTime, DB_TxnFailure_Generic_DataPack, data, DBPrio_Normal);
}

public void DB_TxnSuccess_SaveTime(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
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
	
	Call_OnTimeInserted(client, steamID, mapID, course, mode, style, runTimeMS, teleportsUsed);
} 