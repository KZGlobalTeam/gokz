/*
	Database - Set Cheater
	
	Sets whether player is a cheater in the database.
*/



void DB_SetCheater(int client, bool cheater)
{
	gB_Cheater[client] = cheater;
	
	char query[128];
	
	Transaction txn = SQL_CreateTransaction();
	
	FormatEx(query, sizeof(query), sql_players_set_cheater, cheater ? 1 : 0, GetSteamAccountID(client));
	txn.AddQuery(query);
	
	SQL_ExecuteTransaction(gH_DB, txn, _, DB_TxnFailure_Generic, _, DBPrio_High);
} 