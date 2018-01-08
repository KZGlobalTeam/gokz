/*
	Database - Save Jumpstats Options
	
	Saves player jumpstats options to the database.
*/



void DB_SaveJSOptions(int client)
{
	if (!gB_GOKZJumpstats)
	{
		return;
	}
	
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();
	
	// Update jumpstats options
	FormatEx(query, sizeof(query), 
		sql_jsoptions_update, 
		GOKZ_JS_GetOption(client, JSOption_JumpstatsMaster), 
		GOKZ_JS_GetOption(client, JSOption_MinChatTier), 
		GOKZ_JS_GetOption(client, JSOption_MinConsoleTier), 
		GOKZ_JS_GetOption(client, JSOption_MinSoundTier), 
		GetSteamAccountID(client));
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_High);
} 