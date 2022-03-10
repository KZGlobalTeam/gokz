/*
	Prints the global record times for a map course and mode.
*/


static bool inProgress[MAXPLAYERS + 1];
static bool waitingForOtherCallback[MAXPLAYERS + 1];
static bool isPBQuery[MAXPLAYERS + 1];
static char printRecordsMap[MAXPLAYERS + 1][64];
static int printRecordsCourse[MAXPLAYERS + 1];
static int printRecordsMode[MAXPLAYERS + 1];
static bool printRecordsTimeExists[MAXPLAYERS + 1][TIMETYPE_COUNT];
static float printRecordsTimes[MAXPLAYERS + 1][TIMETYPE_COUNT];
static char printRecordsPlayerNames[MAXPLAYERS + 1][TIMETYPE_COUNT][MAX_NAME_LENGTH];



// =====[ PUBLIC ]=====

void PrintRecords(int client, const char[] map, int course, int mode, const char[] steamid = DEFAULT_STRING)
{
	char mode_str[32];
	
	if (inProgress[client])
	{
		GOKZ_PrintToChat(client, true, "%t", "Please Wait Before Using Command Again");
		return;
	}
	
	GOKZ_GL_GetModeString(mode, mode_str, sizeof(mode_str));
	
	DataPack dpNUB = CreateDataPack();
	dpNUB.WriteCell(GetClientUserId(client));
	dpNUB.WriteCell(TimeType_Nub);
	GlobalAPI_GetRecordsTop(PrintRecordsCallback, dpNUB, steamid, _, _, map, 128, course, mode_str, _, _, 0, 1);
	
	DataPack dpPRO = CreateDataPack();
	dpPRO.WriteCell(GetClientUserId(client));
	dpPRO.WriteCell(TimeType_Pro);
	GlobalAPI_GetRecordsTop(PrintRecordsCallback, dpPRO, steamid, _, _, map, 128, course, mode_str, false, _, 0, 1);
	
	inProgress[client] = true;
	waitingForOtherCallback[client] = true;
	isPBQuery[client] = !StrEqual(steamid, DEFAULT_STRING);
	FormatEx(printRecordsMap[client], sizeof(printRecordsMap[]), map);
	printRecordsCourse[client] = course;
	printRecordsMode[client] = mode;
}

public int PrintRecordsCallback(JSON_Object records, GlobalAPIRequestData request, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int timeType = dp.ReadCell();
	delete dp;
	
	if (request.Failure)
	{
		LogError("Failed to retrieve record from the Global API for printing.");
		return;
	}
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (records.Length <= 0)
	{
		printRecordsTimeExists[client][timeType] = false;
	}
	else
	{
		APIRecord record = view_as<APIRecord>(records.GetObjectIndexed(0));
		printRecordsTimeExists[client][timeType] = true;
		printRecordsTimes[client][timeType] = record.Time;
		record.GetPlayerName(printRecordsPlayerNames[client][timeType], sizeof(printRecordsPlayerNames[][]));
	}
	
	if (!waitingForOtherCallback[client])
	{
		if (isPBQuery[client])
		{
			PrintPBsFinally(client);
		}
		else
		{
			PrintRecordsFinally(client);
		}
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

static void PrintPBsFinally(int client)
{
	// Print GPB header to chat
	if (printRecordsCourse[client] == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "GPB Header", 
			printRecordsMap[client], 
			gC_ModeNamesShort[printRecordsMode[client]]);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "%t", "GPB Header (Bonus)", 
			printRecordsMap[client], 
			printRecordsCourse[client], 
			gC_ModeNamesShort[printRecordsMode[client]]);
	}
	
	// Print GPB times to chat
	if (!printRecordsTimeExists[client][TimeType_Nub])
	{
		GOKZ_PrintToChat(client, false, "%t", "No Global Times Found");
	}
	else if (!printRecordsTimeExists[client][TimeType_Pro])
	{
		GOKZ_PrintToChat(client, false, "%t", "GPB Time - NUB", 
			GOKZ_FormatTime(printRecordsTimes[client][TimeType_Nub]), 
			printRecordsPlayerNames[client][TimeType_Nub]);
		GOKZ_PrintToChat(client, false, "%t", "GPB Time - No PRO Time");
	}
	else
	{
		GOKZ_PrintToChat(client, false, "%t", "GPB Time - NUB", 
			GOKZ_FormatTime(printRecordsTimes[client][TimeType_Nub]), 
			printRecordsPlayerNames[client][TimeType_Nub]);
		GOKZ_PrintToChat(client, false, "%t", "GPB Time - PRO", 
			GOKZ_FormatTime(printRecordsTimes[client][TimeType_Pro]), 
			printRecordsPlayerNames[client][TimeType_Pro]);
	}
}

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
