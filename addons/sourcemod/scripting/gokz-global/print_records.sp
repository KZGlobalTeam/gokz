/*
	Prints the global record times for a map course and mode.
*/


static bool inProgress[MAXPLAYERS + 1];
static bool waitingForOtherCallback[MAXPLAYERS + 1];
static char printRecordsMap[MAXPLAYERS + 1][64];
static int printRecordsCourse[MAXPLAYERS + 1];
static int printRecordsMode[MAXPLAYERS + 1];
static bool printRecordsTimeExists[MAXPLAYERS + 1][TIMETYPE_COUNT];
static float printRecordsTimes[MAXPLAYERS + 1][TIMETYPE_COUNT];
static char printRecordsPlayerNames[MAXPLAYERS + 1][TIMETYPE_COUNT][MAX_NAME_LENGTH];



// =====[ PUBLIC ]=====

void PrintRecords(int client, const char[] map, int course, int mode)
{
	if (inProgress[client])
	{
		GOKZ_PrintToChat(client, true, "%t", "Please Wait Before Using Command Again");
		return;
	}
	
	DataPack dpNUB = CreateDataPack();
	dpNUB.WriteCell(GetClientUserId(client));
	dpNUB.WriteCell(TimeType_Nub);
	GlobalAPI_GetRecordTopEx(map, course, GOKZ_GL_GetGlobalMode(mode), false, 128, 1, PrintRecordsCallback, dpNUB);
	
	DataPack dpPRO = CreateDataPack();
	dpPRO.WriteCell(GetClientUserId(client));
	dpPRO.WriteCell(TimeType_Pro);
	GlobalAPI_GetRecordTopEx(map, course, GOKZ_GL_GetGlobalMode(mode), true, 128, 1, PrintRecordsCallback, dpPRO);
	
	inProgress[client] = true;
	waitingForOtherCallback[client] = true;
	FormatEx(printRecordsMap[client], sizeof(printRecordsMap[]), map);
	printRecordsCourse[client] = course;
	printRecordsMode[client] = mode;
}

public int PrintRecordsCallback(bool failure, const char[] top, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int timeType = dp.ReadCell();
	delete dp;
	
	if (failure)
	{
		LogError("Failed to retrieve NUB record from the global API for printing.");
		return;
	}
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	APIRecordList records = new APIRecordList(top);
	
	if (records.Count() <= 0)
	{
		printRecordsTimeExists[client][timeType] = false;
	}
	else
	{
		char buffer[2048];
		records.GetByIndex(0, buffer, sizeof(buffer));
		
		APIRecord record = new APIRecord(buffer);
		printRecordsTimeExists[client][timeType] = true;
		printRecordsTimes[client][timeType] = record.Time();
		record.PlayerName(printRecordsPlayerNames[client][timeType], sizeof(printRecordsPlayerNames[][]));
	}
	
	if (!waitingForOtherCallback[client])
	{
		PrintRecordsFinally(client);
		inProgress[client] = false;
	}
	else
	{
		waitingForOtherCallback[client] = false;
	}
}



// =====[ EVENTS ]=====

void OnClientPutInServer_PrintRecords(int client)
{
	inProgress[client] = false;
}



// =====[ PRIVATE ]=====

static void PrintRecordsFinally(int client)
{
	// Print GWR header to chat
	if (printRecordsCourse[client] == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "GWR Header", 
			printRecordsMap[client], 
			gC_ModeNamesShort[printRecordsMode[client]]);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "GWR Header (Bonus)", 
			printRecordsMap[client], 
			printRecordsCourse[client], 
			gC_ModeNamesShort[printRecordsMode[client]]);
	}
	
	// Print GWR times to chat
	if (!printRecordsTimeExists[client][TimeType_Nub])
	{
		GOKZ_PrintToChat(client, false, "%t", "No Global Times Found");
	}
	else if (!printRecordsTimeExists[client][TimeType_Pro])
	{
		GOKZ_PrintToChat(client, false, "%t", "GWR Time - NUB", 
			GOKZ_FormatTime(printRecordsTimes[client][TimeType_Nub]), 
			printRecordsPlayerNames[client][TimeType_Nub]);
		GOKZ_PrintToChat(client, false, "%t", "GWR Time - No PRO Time");
	}
	else
	{
		GOKZ_PrintToChat(client, false, "%t", "GWR Time - NUB", 
			GOKZ_FormatTime(printRecordsTimes[client][TimeType_Nub]), 
			printRecordsPlayerNames[client][TimeType_Nub]);
		GOKZ_PrintToChat(client, false, "%t", "GWR Time - PRO", 
			GOKZ_FormatTime(printRecordsTimes[client][TimeType_Pro]), 
			printRecordsPlayerNames[client][TimeType_Pro]);
	}
} 