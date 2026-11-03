/*
	Inserts the player's time into the database.
*/



enum struct UnverifiedTime
{
	int mapID;
	int course;
	int mode;
	int style;
	int runTimeMS;
	int teleportsUsed;
}

static ArrayList unverifiedTimes[MAXPLAYERS + 1];

void DB_SaveTime(int client, int course, int mode, int style, float runTime, int teleportsUsed)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	int mapID = GOKZ_DB_GetCurrentMapID();
	int runTimeMS = GOKZ_DB_TimeFloatToInt(runTime);
	// Setup saves these once Steam has verified them, and later runs queue behind what's still waiting
	if (!IsClientAuthorized(client) || unverifiedTimes[client] != null)
	{
		UnverifiedTime unverifiedTime;
		unverifiedTime.mapID = mapID;
		unverifiedTime.course = course;
		unverifiedTime.mode = mode;
		unverifiedTime.style = style;
		unverifiedTime.runTimeMS = runTimeMS;
		unverifiedTime.teleportsUsed = teleportsUsed;
		if (unverifiedTimes[client] == null)
		{
			unverifiedTimes[client] = new ArrayList(sizeof(UnverifiedTime));
		}
		unverifiedTimes[client].PushArray(unverifiedTime);
		gI_UnverifiedUserID[client] = GetClientUserId(client);
		if (!IsClientAuthorized(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Time Saved Once Verified");
		}
		return;
	}
	
	DB_InsertTime(client, GetSteamAccountID(client), mapID, course, mode, style, runTimeMS, teleportsUsed, false);
}

// One at a time: localranks queries on hearing a time was inserted, and same-priority queries run in order,
// so its lookups for a time can't see the kept times after it
void DB_SaveNextUnverifiedTime(int client, int steamID)
{
	if (unverifiedTimes[client] == null)
	{
		return;
	}
	
	UnverifiedTime unverifiedTime;
	unverifiedTimes[client].GetArray(0, unverifiedTime);
	unverifiedTimes[client].Erase(0);
	if (unverifiedTimes[client].Length == 0)
	{
		delete unverifiedTimes[client];
	}
	DB_InsertTime(client, steamID, unverifiedTime.mapID, unverifiedTime.course, unverifiedTime.mode,
		unverifiedTime.style, unverifiedTime.runTimeMS, unverifiedTime.teleportsUsed, true);
}

void DB_DiscardUnverifiedTimes(int client)
{
	delete unverifiedTimes[client];
}

static void DB_InsertTime(int client, int steamID, int mapID, int course, int mode, int style, int runTimeMS, int teleportsUsed, bool kept)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(steamID);
	data.WriteCell(kept);
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
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SaveTime, DB_TxnFailure_SaveTime, data, DBPrio_Normal);
}

public void DB_TxnSuccess_SaveTime(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int steamID = data.ReadCell();
	bool kept = data.ReadCell();
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
	if (kept)
	{
		DB_SaveNextUnverifiedTime(client, steamID);
	}
} 

public void DB_TxnFailure_SaveTime(Handle db, DataPack data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int steamID = data.ReadCell();
	bool kept = data.ReadCell();
	DB_TxnFailure_Generic_DataPack(db, data, numQueries, error, failIndex, queryData);
	
	// The rest shouldn't stay stuck behind a time that didn't save
	if (kept && IsValidClient(client))
	{
		DB_SaveNextUnverifiedTime(client, steamID);
	}
}

public void DB_DeleteTime(int client, int timeID)
{
	DataPack data = new DataPack();
	data.WriteCell(client == 0 ? -1 : GetClientUserId(client)); // -1 if called from server console
	data.WriteCell(timeID);

	char query[1024];
	FormatEx(query, sizeof(query), sql_times_delete, timeID);

	Transaction txn = SQL_CreateTransaction();
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_TimeDeleted, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_TimeDeleted(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int timeID = data.ReadCell();
	delete data;

	GOKZ_PrintToChatAndLog(client, true, "%t", "Time Deleted", 
		timeID);
}
