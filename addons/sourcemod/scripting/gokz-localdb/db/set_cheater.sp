/*
	Sets whether player is a cheater in the database.
*/



void DB_SetCheater(int cheaterClient, bool cheater)
{
	if (gB_Cheater[cheaterClient] == cheater)
	{
		return;
	}
	
	gB_Cheater[cheaterClient] = cheater;
	
	DataPack data = new DataPack();
	data.WriteCell(-1);
	data.WriteCell(GetSteamAccountID(cheaterClient));
	data.WriteCell(cheater);
	
	char query[128];
	
	Transaction txn = SQL_CreateTransaction();
	
	FormatEx(query, sizeof(query), sql_players_set_cheater, cheater ? 1 : 0, GetSteamAccountID(cheaterClient));
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SetCheater, DB_TxnFailure_Generic, data, DBPrio_High);
}

void DB_SetCheaterSteamID(int client, int cheaterSteamID, bool cheater)
{
	DataPack data = new DataPack();
	data.WriteCell(client == 0 ? -1 : GetClientUserId(client)); // -1 if called from server console
	data.WriteCell(cheaterSteamID);
	data.WriteCell(cheater);
	
	char query[128];
	
	Transaction txn = SQL_CreateTransaction();
	
	FormatEx(query, sizeof(query), sql_players_set_cheater, cheater ? 1 : 0, cheaterSteamID);
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_SetCheater, DB_TxnFailure_Generic, data, DBPrio_High);
}

public void DB_TxnSuccess_SetCheater(Handle db, DataPack data, int numQueries, Handle[] results, any[] queryData)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int steamID = data.ReadCell();
	bool cheater = view_as<bool>(data.ReadCell());
	delete data;
	
	// TODO Translation phrases?
	if (IsValidClient(client))
	{
		if (cheater)
		{
			LogMessage("SteamID32 '%d' was set as a cheater by %L.", steamID, client);
			GOKZ_PrintToChat(client, true, "{grey}SteamID32 '{default}%d{grey}' was set as a cheater.", steamID);
		}
		else
		{
			LogMessage("SteamID32 '%d' was set as not a cheater by %L.", steamID, client);
			GOKZ_PrintToChat(client, true, "{grey}SteamID32 '{default}%d{grey}' was set as not a cheater.", steamID);
		}
	}
	else
	{
		if (cheater)
		{
			LogMessage("SteamID32 '%d' was set as a cheater.", steamID);
		}
		else
		{
			LogMessage("SteamID32 '%d' was set as not a cheater.", steamID);
		}
	}
} 