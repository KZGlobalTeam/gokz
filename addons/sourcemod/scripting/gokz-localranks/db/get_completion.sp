/*
	Gets the number and percentage of maps completed.
*/



void DB_GetCompletion(int client, int targetSteamID, int mode, bool print)
{
	char query[1024];
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(targetSteamID);
	data.WriteCell(mode);
	data.WriteCell(print);
	
	Transaction txn = SQL_CreateTransaction();
	
	// Retrieve Alias of SteamID
	FormatEx(query, sizeof(query), sql_players_getalias, targetSteamID);
	txn.AddQuery(query);
	// Get total number of ranked main courses
	txn.AddQuery(sql_getcount_maincourses);
	// Get number of main course completions
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompleted, targetSteamID, mode);
	txn.AddQuery(query);
	// Get number of main course completions (PRO)
	FormatEx(query, sizeof(query), sql_getcount_maincoursescompletedpro, targetSteamID, mode);
	txn.AddQuery(query);
	
	// Get total number of ranked bonuses
	txn.AddQuery(sql_getcount_bonuses);
	// Get number of bonus completions
	FormatEx(query, sizeof(query), sql_getcount_bonusescompleted, targetSteamID, mode);
	txn.AddQuery(query);
	// Get number of bonus completions (PRO)
	FormatEx(query, sizeof(query), sql_getcount_bonusescompletedpro, targetSteamID, mode);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_GetCompletion, DB_TxnFailure_Generic_DataPack, data, DBPrio_Low);
}

public void DB_TxnSuccess_GetCompletion(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int targetSteamID = data.ReadCell();
	int mode = data.ReadCell();
	bool print = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	char playerName[MAX_NAME_LENGTH];
	int totalMainCourses, completions, completionsPro;
	int totalBonuses, bonusCompletions, bonusCompletionsPro;
	
	// Get Player Name from results
	if (SQL_FetchRow(results[0]))
	{
		SQL_FetchString(results[0], 0, playerName, sizeof(playerName));
	}
	
	// Get total number of main courses
	if (SQL_FetchRow(results[1]))
	{
		totalMainCourses = SQL_FetchInt(results[1], 0);
	}
	// Get completed main courses
	if (SQL_FetchRow(results[2]))
	{
		completions = SQL_FetchInt(results[2], 0);
	}
	// Get completed main courses (PRO)
	if (SQL_FetchRow(results[3]))
	{
		completionsPro = SQL_FetchInt(results[3], 0);
	}
	
	// Get total number of bonuses
	if (SQL_FetchRow(results[4]))
	{
		totalBonuses = SQL_FetchInt(results[4], 0);
	}
	// Get completed bonuses
	if (SQL_FetchRow(results[5])) {
		bonusCompletions = SQL_FetchInt(results[5], 0);
	}
	// Get completed bonuses (PRO)
	if (SQL_FetchRow(results[6]))
	{
		bonusCompletionsPro = SQL_FetchInt(results[6], 0);
	}
	
	// Print completion message to chat if specified
	if (print)
	{
		if (totalMainCourses + totalBonuses == 0)
		{
			GOKZ_PrintToChat(client, true, "%t", "No Ranked Maps");
		}
		else
		{
			GOKZ_PrintToChat(client, true, "%t", "Map Completion", 
				playerName, 
				completions, totalMainCourses, completionsPro, totalMainCourses, 
				bonusCompletions, totalBonuses, bonusCompletionsPro, totalBonuses, 
				gC_ModeNamesShort[mode]);
		}
	}
	
	// Set scoreboard MVP stars to percentage PRO completion of server's default mode
	if (totalMainCourses + totalBonuses != 0 && targetSteamID == GetSteamAccountID(client) && mode == GOKZ_GetDefaultMode())
	{
		CS_SetMVPCount(client, RoundToFloor(float(completionsPro + bonusCompletionsPro) / float(totalMainCourses + totalBonuses) * 100.0));
	}
}

void DB_GetCompletion_FindPlayer(int client, const char[] target, int mode)
{
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(target);
	data.WriteCell(mode);
	
	DB_FindPlayer(target, DB_TxnSuccess_GetCompletion_FindPlayer, data, DBPrio_Low);
}

public void DB_TxnSuccess_GetCompletion_FindPlayer(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	char playerSearch[33];
	data.ReadString(playerSearch, sizeof(playerSearch));
	int mode = data.ReadCell();
	delete data;
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	else if (SQL_GetRowCount(results[0]) == 0)
	{
		GOKZ_PrintToChat(client, true, "%t", "Player Not Found", playerSearch);
		return;
	}
	else if (SQL_FetchRow(results[0]))
	{
		DB_GetCompletion(client, SQL_FetchInt(results[0], 0), mode, true);
	}
} 