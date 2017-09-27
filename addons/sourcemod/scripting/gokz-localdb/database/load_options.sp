/*
	Database - Load Options
	
	Load player options from database.
	
	Notes:
	Inserts the player into the options table if they aren't found,
	then tries to load their options again. This will result in the
	options loaded being the default values in the database.
*/



void DB_LoadOptions(int client)
{
	char query[1024];
	
	Transaction txn = SQL_CreateTransaction();
	
	// Get options for the client
	FormatEx(query, sizeof(query), sql_options_get, GetSteamAccountID(client));
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, DB_TxnSuccess_LoadOptions, DB_TxnFailure_Generic, GetClientUserId(client), DBPrio_High);
}

public void DB_TxnSuccess_LoadOptions(Handle db, int userid, int numQueries, Handle[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (SQL_GetRowCount(results[0]) == 0)
	{
		// No options found for that client, so insert them and try load them again
		char query[1024];
		
		Transaction txn = SQL_CreateTransaction();
		
		// Insert options
		FormatEx(query, sizeof(query), sql_options_insert, GetSteamAccountID(client));
		txn.AddQuery(query);
		
		SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_High);
	}
	else if (SQL_FetchRow(results[0]))
	{
		KZPlayer player = new KZPlayer(client);
		player.mode = SQL_FetchInt(results[0], 0);
		player.style = SQL_FetchInt(results[0], 1);
		player.showingTPMenu = SQL_FetchInt(results[0], 2);
		player.showingInfoPanel = SQL_FetchInt(results[0], 3);
		player.showingKeys = SQL_FetchInt(results[0], 4);
		player.showingPlayers = SQL_FetchInt(results[0], 5);
		player.showingWeapon = SQL_FetchInt(results[0], 6);
		player.autoRestart = SQL_FetchInt(results[0], 7);
		player.slayOnEnd = SQL_FetchInt(results[0], 8);
		player.pistol = SQL_FetchInt(results[0], 9);
		player.checkpointMessages = SQL_FetchInt(results[0], 10);
		player.checkpointSounds = SQL_FetchInt(results[0], 11);
		player.teleportSounds = SQL_FetchInt(results[0], 12);
		player.errorSounds = SQL_FetchInt(results[0], 13);
		player.timerText = SQL_FetchInt(results[0], 14);
		player.speedText = SQL_FetchInt(results[0], 15);
		player.jumpBeam = SQL_FetchInt(results[0], 16);
	}
} 