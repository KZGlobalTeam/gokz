/*
	Database - Load Jumpstats Options
	
	Load player's jumpstats options from database.
*/



void DB_LoadJSOptions(int client)
{
	if (!gB_GOKZJumpstats)
	{
		return;
	}
	
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();
	
	// Get options for the client
	FormatEx(query, sizeof(query), sql_jsoptions_get, GetSteamAccountID(client));
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_LoadJSOptions, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_High);
}

public void DB_TxnSuccess_LoadJSOptions(Handle db, int userid, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	
	if (!gB_GOKZJumpstats || !IsValidClient(client))
	{
		return;
	}
	
	if (SQL_GetRowCount(results[0]) == 0)
	{
		// No options found for that client, so insert them
		char query[1024];
		
		Transaction txn = SQL_CreateTransaction();
		
		// Insert options
		FormatEx(query, sizeof(query), sql_jsoptions_insert, GetSteamAccountID(client));
		txn.AddQuery(query);
		
		SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_High);
	}
	else if (SQL_FetchRow(results[0]))
	{
		GOKZ_JS_SetOption(client, JSOption_JumpstatsMaster, SQL_FetchInt(results[0], 0));
		GOKZ_JS_SetOption(client, JSOption_MinSoundTier, SQL_FetchInt(results[0], 1));
		GOKZ_JS_SetOption(client, JSOption_MinConsoleTier, SQL_FetchInt(results[0], 2));
		GOKZ_JS_SetOption(client, JSOption_MinSoundTier, SQL_FetchInt(results[0], 3));
	}
} 