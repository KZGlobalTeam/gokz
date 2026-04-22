/*
	Displays a replay of the player's personal times on a map course and given mode.
*/



void DB_PlayPBReplay(int client, int targetSteamID, int mapID, int course, int mode)
{
	char query[1024];

	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(course);
	data.WriteCell(mode);

	Transaction txn = SQL_CreateTransaction();

	// Retrieve player name of SteamID
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);
	// Retrieve Map Name of MapID
	FormatEx(query, sizeof(query), sql_maps_getname, mapID);
	txn.AddQuery(query);
	// Check for existence of map course with that MapID and Course
	FormatEx(query, sizeof(query), sql_mapcourses_findid, mapID, course);
	txn.AddQuery(query);
	// Get NUB PB
	FormatEx(query, sizeof(query), sql_getpb, targetSteamID, mapID, course, mode, 10);
	txn.AddQuery(query);
	// Get PRO PB
	FormatEx(query, sizeof(query), sql_getpbpro, targetSteamID, mapID, course, mode, 10);
	txn.AddQuery(query);

	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_PlayPBReplay, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_PlayPBReplay(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int course = data.ReadCell();
	int mode = data.ReadCell();
	delete data;

	if (!IsValidClient(client))
	{
		return;
	}

	char playerName[MAX_NAME_LENGTH];
	char mapName[64];
	char guid[GOKZ_DB_TIME_GUID_MAX];	
	char nubReplayPath[PLATFORM_MAX_PATH], proReplayPath[PLATFORM_MAX_PATH];
	bool nubFoundReplay = false, proFoundReplay = false;
	float nubRunTime, proRunTime;
	int nubTeleportsUsed;

	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, playerName, sizeof(playerName));
	}

	if (SQL_FetchRow(results[1]))
	{
		SQL_FetchString(results[1], 0, mapName, sizeof(mapName));
	}

	if (SQL_GetRowCount(results[2]) == 0)
	{
		if (course == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "Main Course Not Found", mapName);
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Bonus Not Found", mapName, course);
		}
		return;
	}
	
	while (!nubFoundReplay && SQL_FetchRow(results[3]))
	{
		SQL_FetchString(results[3], 2, guid, sizeof(guid));
		GOKZ_RP_FormatRunReplayPath(nubReplayPath, sizeof(nubReplayPath), guid);
		if (FileExists(nubReplayPath))
		{
			nubFoundReplay = true;
			nubRunTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[3], 0));
			nubTeleportsUsed = SQL_FetchInt(results[3], 1);
		}
	}

	while (!proFoundReplay && SQL_FetchRow(results[4]))
	{
		SQL_FetchString(results[4], 1, guid, sizeof(guid));
		GOKZ_RP_FormatRunReplayPath(proReplayPath, sizeof(proReplayPath), guid);
		if (FileExists(proReplayPath))
		{
			proFoundReplay = true;
			proRunTime = GOKZ_DB_TimeIntToFloat(SQL_FetchInt(results[4], 0));
		}
	}

	if (!nubFoundReplay)
	{
		GOKZ_PrintToChat(client, true, "%t", "No Replay Found");
	}
	else if (!proFoundReplay)
	{
		GOKZ_RP_LoadJumpReplay(client, nubReplayPath);
	}
	else if (nubRunTime >= proRunTime)
	{
		GOKZ_RP_LoadJumpReplay(client, proReplayPath);
	}
	else
	{
		Menu menu = new Menu(MenuHandler_PBReplayRunType);
		if (course == 0)
		{
			menu.SetTitle("%T", "PB Replay Run Type Menu - Title", client,
				mapName, gC_ModeNames[mode], playerName);
		}
		else
		{
			menu.SetTitle("%T", "PB Replay Run Type Menu - Title (Bonus)", client,
				mapName, course, gC_ModeNames[mode], playerName);
		}

		char str[64];
		FormatEx(str, sizeof(str), "NUB   %11s  %3d TP", GOKZ_FormatTime(nubRunTime), nubTeleportsUsed);
		menu.AddItem(nubReplayPath, str);
		FormatEx(str, sizeof(str), "PRO   %11s", GOKZ_FormatTime(proRunTime));
		menu.AddItem(proReplayPath, str);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_PBReplayRunType(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char replayPath[PLATFORM_MAX_PATH];
		menu.GetItem(param2, replayPath, sizeof(replayPath));
		GOKZ_RP_LoadJumpReplay(param1, replayPath);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void DB_PlayPBReplay_FindPlayer(int client, const char[] playerName, int mapID, int course, int mode)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(playerName);
	data.WriteCell(mapID);
	data.WriteCell(course);
	data.WriteCell(mode);

	DB_FindPlayer(playerName, DB_TxnSuccess_PlayPBReplay_FindPlayer, data, DBPrio_Low);
}

public void DB_TxnSuccess_PlayPBReplay_FindPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	char playerName[MAX_NAME_LENGTH];

	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	data.ReadString(playerName, sizeof(playerName));
	int mapID = data.ReadCell();
	int course = data.ReadCell();
	int mode = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	else if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", playerName);
	}
	else if (SQL_FetchRow(results[0]))
	{
		int targetSteamID = SQL_FetchInt(results[0], 0);
		DB_PlayPBReplay(client, targetSteamID, mapID, course, mode);
	}
}
